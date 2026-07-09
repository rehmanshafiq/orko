import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filters.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';
import 'package:orko_hubco/features/map/presentation/widgets/home_bottom_sheet_widget.dart';
import 'package:orko_hubco/features/map/presentation/widgets/home_error_banner_widget.dart';
import 'package:orko_hubco/features/map/presentation/widgets/map_control_button_widget.dart';
import 'package:orko_hubco/features/map/presentation/widgets/map_top_actions_widget.dart';

class HomeMobileView extends StatefulWidget {
  const HomeMobileView({super.key});

  /// Set by the Filter results screen when the user taps a station card: the
  /// home map listens to this and animates its camera to the station's marker.
  /// Reset back to null once handled so the same station can be focused again.
  static final ValueNotifier<HubcoLocationEntity?> focusStationNotifier =
      ValueNotifier<HubcoLocationEntity?>(null);

  @override
  State<HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<HomeMobileView> {
  static const LatLng _center = LatLng(24.8607, 67.0011);
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#141825"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#132822"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3D424C"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#3D424C"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#3D424C"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3D424C"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#3D424C"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#3D424C"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#080D17"}]}
]
''';

  GoogleMapController? _mapController;
  Brightness? _lastAppliedBrightness;

  Future<void> _applyMapStyleForTheme(Brightness brightness) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.setMapStyle(
      brightness == Brightness.dark ? _darkMapStyle : null,
    );
  }

  /// True only after the dark style has been confirmed painted.
  /// The black cover overlay is shown whenever this is false,
  /// hiding any white flash from the Google Maps SDK.
  bool _mapReady = false;

  /// Drives [GoogleMap.myLocationEnabled]. Kept in sync with runtime permission
  /// so the SDK actually paints the blue dot (it often ignores `true` until
  /// after permission is granted and the widget rebuilds).
  bool _mapMyLocationEnabled = false;

  Set<Marker> _markers = const <Marker>{};
  List<HubcoLocationEntity> _locations = const [];

  /// Nearby-stations chip filters (client-side), derived from the API data:
  /// `available` → the "Available Now" chip; `type` → one chip per connector
  /// kind (DC, AC, AC/DC).
  bool _availableNowSelected = false;
  final Set<String> _selectedTypes = {};

  final Map<_ChargingStationMarkerKind, BitmapDescriptor> _chargingStationIcons =
      {};

  /// Zoom used when framing stations on first load.
  static const double _initialZoom = 5.2;

  /// Camera position after the map first frames loaded stations; restored by zoom out.
  CameraPosition? _initialCameraPosition;

  /// Whether the zoom-out control is visible (user has zoomed in past the initial level).
  bool _showZoomOutButton = false;

  /// Whether the results sheet is expanded to fill the screen. Only usable when
  /// filters are applied; forced back to false whenever filters are cleared.
  bool _sheetExpanded = false;

  /// Unread notification count for the bell badge. 0 hides the badge.
  int _unreadCount = 0;

  /// Periodic poll for the unread count (no live push from the backend).
  Timer? _unreadPollTimer;
  static const Duration _unreadPollInterval = Duration(seconds: 45);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    // Poll periodically; guests are skipped inside the refresh method.
    _unreadPollTimer = Timer.periodic(
      _unreadPollInterval,
      (_) => _refreshUnreadCount(),
    );
    HomeMobileView.focusStationNotifier.addListener(_onFocusStationRequested);
  }

  @override
  void dispose() {
    HomeMobileView.focusStationNotifier.removeListener(_onFocusStationRequested);
    _unreadPollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Zoom used when focusing a single station from the filter results screen.
  static const double _focusStationZoom = 16;

  /// Handles a focus request coming from the Filter results screen: animates
  /// the map camera to the selected station, then clears the request.
  Future<void> _onFocusStationRequested() async {
    final station = HomeMobileView.focusStationNotifier.value;
    if (station == null) return;
    // Clear immediately so tapping the same station again re-triggers this.
    HomeMobileView.focusStationNotifier.value = null;

    final controller = _mapController;
    if (controller == null || !mounted) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(station.latitude, station.longitude),
        _focusStationZoom,
      ),
    );
    _onCameraPositionChanged(_focusStationZoom);
  }

  /// Fetches the unread badge count. No-op for guests (the endpoint is
  /// auth-only) and silently ignores failures so the map UI is never blocked.
  Future<void> _refreshUnreadCount() async {
    if (AppStorage.isGuest) {
      if (mounted && _unreadCount != 0) setState(() => _unreadCount = 0);
      return;
    }
    final result = await sl<GetUnreadCountUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (_) {},
      (count) {
        if (count != _unreadCount) setState(() => _unreadCount = count);
      },
    );
  }

  /// Opens the notifications list (guests are prompted to authenticate), then
  /// refreshes the badge on return.
  Future<void> _openNotifications() async {
    if (AppStorage.isGuest) {
      AuthRequiredDialog.show(
        context,
        message:
            'Please log in or create an account to view your notifications.',
      );
      return;
    }
    await context.push('/notifications');
    await _refreshUnreadCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastAppliedBrightness == brightness) return;
    _lastAppliedBrightness = brightness;
    unawaited(_applyMapStyleForTheme(brightness));
  }

  // ── Map callbacks ─────────────────────────────────────────────────────────

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // Cover → apply style → reveal. One-time setup on first load.
    if (mounted) setState(() => _mapReady = false);
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final brightness = Theme.of(context).brightness;
    _lastAppliedBrightness = brightness;
    await _applyMapStyleForTheme(brightness);
    if (!mounted) return;

    setState(() => _mapReady = true);

    // Locations may have already loaded before the map was created (the asset
    // loads fast, and the permission dialog can delay this callback). In that
    // case the camera move in [_onLocationsLoaded] was skipped because the
    // controller didn't exist yet — so position the camera now.
    unawaited(_moveCameraToLocations());

    // Blue dot: enable native layer once location permission is known/granted.
    unawaited(_syncMapMyLocationLayer());
  }

  /// Animates the camera to frame the loaded stations. Safe to call from either
  /// [_onMapCreated] or [_onLocationsLoaded]; it no-ops until both the map
  /// controller and at least one location are available.
  Future<void> _moveCameraToLocations() async {
    final controller = _mapController;
    if (controller == null || _locations.isEmpty) return;
    final first = _locations.first;
    final position = CameraPosition(
      target: LatLng(first.latitude, first.longitude),
      zoom: _initialZoom,
    );
    _initialCameraPosition = position;
    if (_showZoomOutButton) {
      setState(() => _showZoomOutButton = false);
    }
    await controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  double get _baselineZoom => _initialCameraPosition?.zoom ?? 13.8;

  void _onCameraPositionChanged(double zoom) {
    final show = zoom > _baselineZoom + 0.05;
    if (show != _showZoomOutButton) {
      setState(() => _showZoomOutButton = show);
    }
  }

  /// Updates [GoogleMap.myLocationEnabled] from current Geolocator permission so
  /// the blue “current location” dot can render.
  ///
  /// This only *checks* permission — it never requests it. [MapCubit] owns the
  /// single permission request on load; requesting here too races with it and
  /// throws `PermissionRequestInProgressException`, which can stall the location
  /// flow on first launch.
  Future<void> _syncMapMyLocationLayer() async {
    if (!mounted) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _mapMyLocationEnabled = false);
        return;
      }

      final permission = await Geolocator.checkPermission();
      final show = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (mounted) setState(() => _mapMyLocationEnabled = show);
    } catch (_) {
      // Permission still being requested elsewhere; leave the layer as-is.
    }
  }

  /// Called by BlocConsumer listener on every [MapLoaded] event.
  ///
  /// The Google Maps Flutter SDK briefly reverts to white default tiles
  /// whenever its [markers] property is updated through setState. This
  /// method hides that flash behind the black cover, reapplies the dark
  /// style, then reveals the finished map.
  Future<void> _onLocationsLoaded(List<HubcoLocationEntity> locations) async {
    if (!mounted) return;

    // Step 1 ── Cover the map so the upcoming white flash is invisible.
    setState(() => _mapReady = false);

    // Step 2 ── Wait for the cover to be painted before anything changes.
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    _locations = locations;

    // Step 3 ── Build station markers. The SDK flashes white here — it's hidden.
    await _rebuildMarkers();
    if (!mounted) return;

    // Step 4 ── Reapply dark style; the SDK reverted it on redraw.
    await _applyMapStyleForTheme(Theme.of(context).brightness);
    if (!mounted) return;

    // Step 5 ── Animate camera to first location. If the controller isn't ready
    // yet, [_onMapCreated] will run this once the map is created.
    await _moveCameraToLocations();

    if (!mounted) return;

    // Step 6 ── Reveal the now-dark map.
    setState(() => _mapReady = true);

    // Map rebuild can drop the my-location layer; re-apply if still permitted.
    unawaited(_syncMapMyLocationLayer());
  }

  /// Logical width/height of the station pin bitmap. Sized so the teardrop pin
  /// plus its glow halo stay crisp at typical map zoom levels.
  static const double _chargingStationMarkerSize = 60;

  /// Fraction of the bitmap height where the pin tip sits; used as the marker
  /// anchor so the tip points at the station's exact coordinate.
  static const double _stationPinTipFraction = 52 / 60;

  /// Standard location pins (green = active, grey = inactive), drawn on a
  /// canvas with a soft radial glow behind the pin so charging stations stand
  /// out on the map at a glance. Cached after the first build.
  Future<Map<_ChargingStationMarkerKind, BitmapDescriptor?>>
      _resolveChargingStationIcon() async {
    if (_chargingStationIcons.length ==
        _ChargingStationMarkerKind.values.length) {
      return {
        for (final kind in _ChargingStationMarkerKind.values)
          kind: _chargingStationIcons[kind],
      };
    }
    if (!mounted) return const {};

    for (final kind in _ChargingStationMarkerKind.values) {
      final color = kind == _ChargingStationMarkerKind.green
          ? AppColors.primaryDarkColor
          : AppColors.greyColor;
      _chargingStationIcons[kind] = await _buildStationPinBitmap(color: color);
    }

    return {
      for (final kind in _ChargingStationMarkerKind.values)
        kind: _chargingStationIcons[kind],
    };
  }

  /// Draws a teardrop location pin in [color] (white outline + lightning bolt)
  /// over a subtle radial glow, and returns it as a [BitmapDescriptor].
  ///
  /// Geometry lives on a 60×60 logical grid scaled by [u]: glow and pin head
  /// centered at (30, 24), pin tip at (30, 52) — see [_stationPinTipFraction].
  Future<BitmapDescriptor> _buildStationPinBitmap({required Color color}) async {
    final dpr = mounted ? MediaQuery.devicePixelRatioOf(context) : 3.0;
    final size =
        (_chargingStationMarkerSize * dpr).clamp(1.0, 512.0).toDouble();
    final u = size / 60;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final headCenter = Offset(30 * u, 24 * u);

    // Glow halo behind the pin.
    canvas.drawCircle(
      headCenter,
      27 * u,
      Paint()
        ..shader = ui.Gradient.radial(
          headCenter,
          27 * u,
          [color.withValues(alpha: 0.45), color.withValues(alpha: 0.0)],
        ),
    );

    // Teardrop pin: tip → left edge → arc over the head → right edge → tip.
    final pin = Path()
      ..moveTo(30 * u, 52 * u)
      ..quadraticBezierTo(20 * u, 42 * u, 16.8 * u, 28.8 * u)
      ..arcTo(
        Rect.fromCircle(center: headCenter, radius: 14 * u),
        160 * math.pi / 180,
        220 * math.pi / 180,
        false,
      )
      ..quadraticBezierTo(40 * u, 42 * u, 30 * u, 52 * u)
      ..close();
    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawPath(
      pin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * u
        ..color = AppColors.whiteColor,
    );

    // Lightning bolt in the pin head, keeping the charging identity.
    const boltPoints = <Offset>[
      Offset(2.5, -7),
      Offset(-4.5, 1),
      Offset(-1, 1),
      Offset(-2.5, 7),
      Offset(4.5, -1),
      Offset(1, -1),
    ];
    final bolt = Path()
      ..addPolygon(
        [for (final p in boltPoints) headCenter + p * (1.1 * u)],
        true,
      );
    canvas.drawPath(bolt, Paint()..color = AppColors.whiteColor);

    final image = await recorder.endRecording().toImage(
          size.round(),
          size.round(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (bytes == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      width: _chargingStationMarkerSize,
    );
  }

  /// Green marker when the station is active (`status: true`), grey otherwise.
  _ChargingStationMarkerKind _markerKindFor(HubcoLocationEntity station) {
    return station.status
        ? _ChargingStationMarkerKind.green
        : _ChargingStationMarkerKind.grey;
  }

  // ── Markers ──────────────────────────────────────────────────────────────

  /// Renders one pin per station in [_locations] — no clustering, so the map
  /// always shows every charging station individually regardless of zoom.
  Future<void> _rebuildMarkers() async {
    if (!mounted) return;

    if (_locations.isEmpty) {
      setState(() => _markers = const <Marker>{});
      return;
    }

    final stationIcons = await _resolveChargingStationIcon();
    if (!mounted) return;

    setState(() {
      _markers = {
        for (final station in _locations)
          _toMarker(station, stationIcons[_markerKindFor(station)]),
      };
    });
  }

  /// Centers the map on the device location (same idea as Google Maps’ target button).
  Future<void> _goToMyLocation() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Turn on location services to see your position on the map.',
          isError: true,
        );
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Location permission is required to go to your current position.',
          isError: true,
        );
      }
      return;
    }

    if (mounted) setState(() => _mapMyLocationEnabled = true);

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Could not get your current location. Try again.',
          isError: true,
        );
      }
    }
  }

  /// Restores the camera to the initial framing used when stations first load.
  Future<void> _zoomOutToInitial() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;

    final position = _initialCameraPosition ??
        const CameraPosition(target: _center, zoom: 13.8);

    await controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  Marker _toMarker(HubcoLocationEntity station, BitmapDescriptor? icon) {
    return Marker(
      markerId: MarkerId(station.id.toString()),
      position: LatLng(station.latitude, station.longitude),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      // Pin tip (not bitmap bottom — the glow pads it) points at the station.
      anchor: const Offset(0.5, _stationPinTipFraction),
      infoWindow: InfoWindow(title: station.name),
      onTap: () => context.push('/station-detail', extra: station),
    );
  }

  /// Clears the applied filters: reloads the map with an empty filter set, which
  /// reverts the sheet to "Nearby Stations" (30 km cap), repaints every charger
  /// marker, and hides the "Clear Filter" affordance. Also collapses the sheet.
  void _clearFilters() {
    if (_sheetExpanded) setState(() => _sheetExpanded = false);
    context.read<MapCubit>().applyFilters(const StationFilters());
  }

  /// Handles a vertical drag on the sheet header. Swiping up expands the sheet
  /// to full screen (only when filters are applied); swiping down collapses it.
  void _onSheetDragEnd(DragEndDetails details, {required bool filtersApplied}) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -80 && filtersApplied && !_sheetExpanded) {
      setState(() => _sheetExpanded = true);
    } else if (velocity > 80 && _sheetExpanded) {
      setState(() => _sheetExpanded = false);
    }
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) context.go('/login');
        },
        child: BlocConsumer<MapCubit, MapState>(
          listener: (context, state) {
            if (state is MapLoaded) {
              _onLocationsLoaded(state.locations);
            }
          },
          builder: (context, state) {
            final errorMessage = state is MapError ? state.message : null;
            // Filters drive the "Results"/full-screen behaviour; only usable
            // when something is actually filtered.
            final filtersApplied =
                !context.read<MapCubit>().currentFilters.isEmpty;
            final sheetExpanded = _sheetExpanded && filtersApplied;

            return Stack(
              children: [
                // ── Google Map ─────────────────────────────────────────────
                // Fades in only after _mapReady is true (dark style confirmed).
                AnimatedOpacity(
                  opacity: _mapReady ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _center,
                      zoom: 13.8,
                    ),
                    onMapCreated: _onMapCreated,
                    onCameraMove: (position) =>
                        _onCameraPositionChanged(position.zoom),
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: _mapMyLocationEnabled,
                    zoomControlsEnabled: false,
                    buildingsEnabled: true,
                    markers: _markers,
                  ),
                ),

                // ── Black cover ────────────────────────────────────────────
                // Sits above the map and below all UI. Visible whenever the
                // map is not yet dark, hiding any white tile flash entirely.
                if (!_mapReady)
                  Positioned.fill(
                    child: ColoredBox(color: ui.scaffoldBackground),
                  ),

                // ── UI Overlay ─────────────────────────────────────────────
                SafeArea(
                  child: Column(
                    children: [
                      10.verticalSpace,
                      Padding(
                        padding: AppUtils.horizontal16Padding,
                        child: MapTopActionsWidget(
                          stationCount: _locations.length,
                          unreadCount: _unreadCount,
                          onNotificationsTap: _openNotifications,
                        ),
                      ),
                      if (errorMessage != null) ...[
                        8.verticalSpace,
                        Padding(
                          padding: AppUtils.horizontal16Padding,
                          child: HomeErrorBannerWidget(errorMessage),
                        ),
                      ],
                      // When the sheet is expanded it fills the remaining space
                      // (covering the map, like the Filter results screen);
                      // otherwise the map controls float above the compact sheet.
                      if (sheetExpanded)
                        Expanded(child: _bottomSheet(expanded: true))
                      else ...[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 16, bottom: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_showZoomOutButton) ...[
                                    MapControlButtonWidget(
                                      icon: Icons.zoom_out_map_rounded,
                                      onTap: _zoomOutToInitial,
                                    ),
                                    8.verticalSpace,
                                  ],
                                  if (state is! MapLoading)
                                    MapControlButtonWidget(
                                      icon: Icons.my_location_rounded,
                                      onTap: _goToMyLocation,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _bottomSheet(expanded: false),
                      ],
                    ],
                  ),
                ),

                // ── Loading spinner ────────────────────────────────────────
                if (state is MapLoading)
                  Center(
                    child: CircularProgressIndicator(color: ui.brandPrimary),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bottomSheet({required bool expanded}) {
    final filtersApplied = !context.read<MapCubit>().currentFilters.isEmpty;
    return HomeBottomSheetWidget(
      expanded: expanded,
      filtersApplied: filtersApplied,
      locations: _locations,
      availableNowSelected: _availableNowSelected,
      selectedTypes: _selectedTypes,
      onClearFilters: _clearFilters,
      onToggleAvailableNow: () =>
          setState(() => _availableNowSelected = !_availableNowSelected),
      onToggleType: _toggleType,
      onHeaderDragEnd: (d) =>
          _onSheetDragEnd(d, filtersApplied: filtersApplied),
    );
  }
}

enum _ChargingStationMarkerKind { grey, green }
