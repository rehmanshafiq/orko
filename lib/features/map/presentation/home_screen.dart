import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';
import 'package:orko_hubco/features/map/presentation/widgets/map_filters_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  static const int _portsPerMarker = 5;

  final Map<_ChargingStationMarkerKind, BitmapDescriptor> _chargingStationIcons =
      {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(first.latitude, first.longitude),
          zoom: 5.2,
        ),
      ),
    );
  }

  /// Updates [GoogleMap.myLocationEnabled] from current Geolocator permission so
  /// the blue “current location” dot can render.
  Future<void> _syncMapMyLocationLayer() async {
    if (!mounted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _mapMyLocationEnabled = false);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final show = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (mounted) setState(() => _mapMyLocationEnabled = show);
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

    final stationIcons = await _resolveChargingStationIcon();
    if (!mounted) return;

    // Step 3 ── Update markers. The SDK flashes white here — it's hidden.
    setState(() {
      _locations = locations;
      _markers = locations
          .map(
            (s) => _toMarker(
              s,
              stationIcons[_markerKindFor(s)],
            ),
          )
          .toSet();
    });

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

  static const double _chargingStationMarkerSize = 20;

  /// Loads green / grey / orange marker assets (cached). Each station maps to
  /// one of five availability levels (0–5 ports) and picks the matching icon.
  Future<Map<_ChargingStationMarkerKind, BitmapDescriptor?>>
      _resolveChargingStationIcon() async {
    if (_chargingStationIcons.length == _ChargingStationMarkerKind.values.length) {
      return {
        for (final kind in _ChargingStationMarkerKind.values)
          kind: _chargingStationIcons[kind],
      };
    }
    if (!mounted) return const {};

    final results = await Future.wait([
      _loadChargingStationMarkerAsset(
        AppImages.markerGreen,
        _ChargingStationMarkerKind.green,
      ),
      // _loadChargingStationMarkerAsset(
      //   AppImages.markerGrey,
      //   _ChargingStationMarkerKind.grey,
      // ),
      _loadChargingStationMarkerAsset(
        AppImages.markerGrey,
        _ChargingStationMarkerKind.orange,
      ),
    ]);

    return {
      for (final entry in results)
        if (entry != null) entry.key: entry.value,
    };
  }

  /// Google Maps on Android opens assets via the native AssetManager, which can
  /// miss files under a directory-only pubspec entry. Load through [rootBundle]
  /// and pass PNG bytes so markers render reliably after a full rebuild.
  Future<MapEntry<_ChargingStationMarkerKind, BitmapDescriptor>?>
      _loadChargingStationMarkerAsset(
    String assetPath,
    _ChargingStationMarkerKind kind,
  ) async {
    if (!mounted) return null;
    try {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final targetWidth =
          (_chargingStationMarkerSize * dpr).round().clamp(1, 512);

      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();

      if (byteData == null) return null;

      final icon = BitmapDescriptor.bytes(
        byteData.buffer.asUint8List(),
        width: _chargingStationMarkerSize,
      );
      _chargingStationIcons[kind] = icon;
      return MapEntry(kind, icon);
    } catch (e, st) {
      debugPrint('❌ Marker asset $assetPath failed: $e\n$st');
      return null;
    }
  }

  int _availablePortsForMarker(HubcoLocationEntity station) {
    if (!station.status) return 0;
    return 1 + station.id % _portsPerMarker;
  }

  _ChargingStationMarkerKind _markerKindFor(HubcoLocationEntity station) {
    final available = _availablePortsForMarker(station);
    if (available == 0) return _ChargingStationMarkerKind.grey;
    if (available <= 2) return _ChargingStationMarkerKind.orange;
    return _ChargingStationMarkerKind.green;
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
                        child: _buildTopActions(context),
                      ),
                      if (errorMessage != null) ...[
                        8.verticalSpace,
                        Padding(
                          padding: AppUtils.horizontal16Padding,
                          child: _buildErrorBanner(context, errorMessage),
                        ),
                      ],
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16, bottom: 16),
                            child: _buildMyLocationButton(context),
                          ),
                        ),
                      ),
                      _buildBottomSheet(context),
                    ],
                  ),
                ),

                // ── Loading spinner ────────────────────────────────────────
                if (state is MapLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: ui.brandPrimary,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _buildMyLocationButton(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _goToMyLocation,
        borderRadius: BorderRadius.circular(8.r),
        child: Ink(
          height: 52.h,
          width: 52.w,
          decoration: BoxDecoration(
            color: ui.cardBackground.withValues(alpha: ui.isLight ? 0.95 : 0.2),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: ui.borderSubtle,
            ),
          ),
          child: Icon(
            Icons.my_location_rounded,
            size: 26,
            color: ui.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.28)),
      ),
      child: AppText(
        message,
        color: AppUiColors.of(context).textPrimary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }

  Widget _buildTopActions(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.transparentColor,
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(10.r),
              child: Ink(
                padding: AppUtils.homeTopSearchPadding,
                decoration: BoxDecoration(
                  color: ui.searchBackground,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: ui.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: ui.textMuted,
                      size: 25,
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: AppText(
                        'Search stations or locations',
                        color: ui.textMuted,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ),
                    8.horizontalSpace,
                    _topActionIcon(
                      context,
                      Icons.tune_rounded,
                      isPrimary: true,
                      isCompact: true,
                      onTap: () => MapFiltersBottomSheet.show(
                        context,
                        stationCount: _locations.length,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        10.horizontalSpace,
        _topActionIcon(context, Icons.notifications_none_rounded),
      ],
    );
  }

  Widget _topActionIcon(
    BuildContext context,
    IconData icon, {
    bool isPrimary = false,
    bool isCompact = false,
    VoidCallback? onTap,
  }) {
    final ui = AppUiColors.of(context);
    final radius = BorderRadius.circular(8.r);
    final child = Container(
      height: isCompact ? 30.h : 52.h,
      width: isCompact ? 30.w : 52.w,
      decoration: BoxDecoration(
        color: isPrimary ? ui.brandPrimary : ui.searchBackground,
        borderRadius: radius,
        border: Border.all(
          color: isPrimary ? ui.brandPrimary : ui.borderSubtle,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: isCompact ? 15 : 26,
        color: isPrimary
            ? (ui.isLight ? AppColors.whiteColor : AppColors.blackColor)
            : ui.textMuted,
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: child,
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    final ui = AppUiColors.of(context);
    final nearbyStations = _locations.toList();

    return Container(
      padding: AppUtils.homeBottomSheetPadding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            child: Container(
              height: 3.h,
              width: 66.w,
              decoration: BoxDecoration(
                color: ui.textSecondary.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          12.verticalSpace,
          AppText(
            'Nearby Stations',
            color: ui.textPrimary,
            fontSize: FontSizes.font24Sp,
            fontWeight: FontWeights.weight600,
          ),
          10.verticalSpace,
          Row(
            children: [
              _chip(context, 'Available Now', isActive: true),
              8.horizontalSpace,
              _chip(context, 'DC Fast'),
              8.horizontalSpace,
              _chip(context, 'AC Level 2'),
            ],
          ),
          12.verticalSpace,
          if (nearbyStations.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: AppText(
                'No stations available',
                color: ui.textSecondary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
            )
          else
            SizedBox(
              height: 118.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearbyStations.length,
                separatorBuilder: (_, __) => 8.horizontalSpace,
                itemBuilder: (context, index) {
                  final station = nearbyStations[index];
                  return SizedBox(
                    width: 280.w,
                    child: _stationCard(context, station),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Marker _toMarker(HubcoLocationEntity station, BitmapDescriptor? icon) {
    return Marker(
      markerId: MarkerId(station.id.toString()),
      position: LatLng(station.latitude, station.longitude),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(title: station.name),
      onTap: () => context.push('/station-detail', extra: station),
    );
  }

  Widget _chip(BuildContext context, String text, {bool isActive = false}) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.homeFilterChipPadding,
      decoration: BoxDecoration(
        color: isActive
            ? ui.brandPrimary.withValues(alpha: 0.22)
            : ui.innerCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? ui.brandPrimary : ui.borderSubtle,
        ),
      ),
      child: AppText(
        text,
        color: isActive ? ui.brandPrimary : ui.textPrimary.withValues(alpha: 0.8),
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight400,
      ),
    );
  }

  static const _stationDistances = ['1.8 km', '2.8 km'];

  String _stationDistanceLabel(HubcoLocationEntity station) {
    return _stationDistances[station.id % _stationDistances.length];
  }

  String _stationAvailabilityLabel(HubcoLocationEntity station) {
    final available = _availablePortsForMarker(station);
    return '$available/$_portsPerMarker Available';
  }

  String _stationPriceLabel(HubcoLocationEntity station) {
    final price = 45 + station.id % 35;
    return 'Rs $price/kWh';
  }

  Widget _stationCard(BuildContext context, HubcoLocationEntity station) {
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () => context.push('/station-detail', extra: station),
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
          decoration: BoxDecoration(
            color: ui.innerCardBg,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: ui.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      station.name,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  8.horizontalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: ui.textPrimary,
                          size: 10.sp,
                        ),
                        4.horizontalSpace,
                        AppText(
                          _stationDistanceLabel(station),
                          color: ui.textPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              4.verticalSpace,
              AppText(
                _stationAvailabilityLabel(station),
                color: ui.brandPrimary,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight500,
              ),
              8.verticalSpace,
              Row(
                children: [
                  _StationPlugIconsRow(color: ui.textSecondary),
                  const Spacer(),
                  Flexible(
                    child: AppText(
                      _stationPriceLabel(station),
                      color: ui.textSecondary,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChargingStationMarkerKind { green, grey, orange }

class _StationPlugIconsRow extends StatelessWidget {
  const _StationPlugIconsRow({required this.color});

  final Color color;

  static const _iconSize = 34.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // _PlugIcon(assetPath: AppImages.icCcs, color: color),
        // 2.horizontalSpace,
        // _PlugIcon(assetPath: AppImages.icCcs1, color: color),
        // 2.horizontalSpace,
        _PlugIcon(assetPath: AppImages.icCss2, color: color),
        50.horizontalSpace,
      ],
    );
  }
}

class _PlugIcon extends StatelessWidget {
  const _PlugIcon({
    required this.assetPath,
    required this.color,
  });

  final String assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = _StationPlugIconsRow._iconSize.sp;

    if (assetPath.endsWith('.svg')) {
      return AppSvgImageView(
        appImagePath: assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
      );
    }

    return AppPngImageView(
      appImagePath: assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}