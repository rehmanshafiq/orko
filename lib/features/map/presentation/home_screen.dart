import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
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

  static const Color _mapCoverColor = Color(0xFF0C4A4E);
  static const Color _mapHomeGreen = Color(0xFF00796B);
  static const Color _mapHomeGreenBright = Color(0xFF00A878);
  static const Color _mapHomeTextDark = Color(0xFF1B4332);
  static const Color _mapHomeTextMuted = Color(0xFF6B7280);
  static const Color _mapHomeCardBg = Color(0xFFF3F4F6);

  static const String _tealMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0c4a4e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#7dd3e8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0c4a4e"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#0f5c60"}]},
  {"featureType":"poi","elementType":"labels.text","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#136b70"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#5eead4"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#17838a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1a9aa3"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#0f5c60"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#083a3e"}]}
]
''';

  GoogleMapController? _mapController;
  Brightness? _lastAppliedBrightness;

  Future<void> _applyMapStyleForTheme(Brightness brightness) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.setMapStyle(_tealMapStyle);
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

  BitmapDescriptor? _chargingStationIcon;

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

    // Blue dot: enable native layer once location permission is known/granted.
    unawaited(_syncMapMyLocationLayer());
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

    final stationIcon = await _resolveChargingStationIcon();
    if (!mounted) return;

    // Step 3 ── Update markers. The SDK flashes white here — it's hidden.
    setState(() {
      _locations = locations;
      _markers = locations.map((s) => _toMarker(s, stationIcon)).toSet();
    });

    // Step 4 ── Reapply dark style; the SDK reverted it on redraw.
    await _applyMapStyleForTheme(Theme.of(context).brightness);
    if (!mounted) return;

    // Step 5 ── Animate camera to first location.
    if (locations.isNotEmpty && _mapController != null) {
      final first = locations.first;
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(first.latitude, first.longitude),
            zoom: 5.2,
          ),
        ),
      );
    }

    if (!mounted) return;

    // Step 6 ── Reveal the now-dark map.
    setState(() => _mapReady = true);

    // Map rebuild can drop the my-location layer; re-apply if still permitted.
    unawaited(_syncMapMyLocationLayer());
  }

  static const double _chargingStationMarkerSize = 40;

  Future<BitmapDescriptor?> _resolveChargingStationIcon() async {
    if (_chargingStationIcon != null) return _chargingStationIcon;
    if (!mounted) return null;
    try {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final size = _chargingStationMarkerSize * dpr;
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final center = Offset(size / 2, size / 2);
      final radius = size * 0.38;

      final fillPaint = Paint()..color = const Color(0xFFEF4444);
      canvas.drawCircle(center, radius, fillPaint);

      final borderPaint = Paint()
        ..color = AppColors.whiteColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.07;
      canvas.drawCircle(center, radius - borderPaint.strokeWidth / 2, borderPaint);

      final iconData = Icons.ev_station_rounded;
      final iconPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: size * 0.42,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: AppColors.whiteColor,
          ),
        ),
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          center.dx - iconPainter.width / 2,
          center.dy - iconPainter.height / 2,
        ),
      );

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final icon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      _chargingStationIcon = icon;
      return icon;
    } catch (e, st) {
      debugPrint('❌ Marker icon failed: $e\n$st');
      return null;
    }
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
                  const Positioned.fill(
                    child: ColoredBox(color: _mapCoverColor),
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
                            padding: EdgeInsets.only(right: 16.w, bottom: 16.h),
                            child: _buildMapFloatingButtons(),
                          ),
                        ),
                      ),
                      _buildBottomSheet(context),
                    ],
                  ),
                ),

                // ── Loading spinner ────────────────────────────────────────
                if (state is MapLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDarkColor,
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

  Widget _buildMapFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapFloatingButton(
          icon: Icons.my_location_rounded,
          backgroundColor: _mapHomeGreenBright,
          iconColor: AppColors.whiteColor,
          onTap: _goToMyLocation,
        ),
        12.verticalSpace,
        _MapFloatingButton(
          icon: Icons.layers_rounded,
          backgroundColor: AppColors.whiteColor,
          iconColor: _mapHomeTextMuted,
          onTap: () {},
        ),
      ],
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
                  color: ui.cardBackground.withValues(alpha: ui.isLight ? 0.96 : 0.2),
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
                      size: 22,
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
        color: isPrimary
            ? AppColors.primaryDarkColor
            : ui.cardBackground.withValues(alpha: ui.isLight ? 0.96 : 0.2),
        borderRadius: radius,
        border: Border.all(
          color: isPrimary
              ? AppColors.primaryDarkColor
              : ui.borderSubtle,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: isCompact ? 15 : 26,
        color: isPrimary ? AppColors.whiteColor : ui.textPrimary,
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
    final nearbyStations = _locations.toList();
    final availableCount = nearbyStations.where((s) => s.status).length;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              height: 4.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: AppColors.shimmerGreyColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          18.verticalSpace,
          AppText(
            'NEARBY STATIONS',
            color: _mapHomeGreen,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
            letterSpacing: 1.2,
          ),
          8.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppText(
                  'Clifton, Karachi',
                  color: _mapHomeTextDark,
                  fontSize: FontSizes.font24Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: AppColors.shimmerGreyColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: const BoxDecoration(
                        color: _mapHomeGreenBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                    6.horizontalSpace,
                    AppText(
                      '$availableCount Available',
                      color: _mapHomeTextDark,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ],
                ),
              ),
            ],
          ),
          18.verticalSpace,
          if (nearbyStations.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: AppText(
                'No stations available',
                color: _mapHomeTextMuted,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
            )
          else
            SizedBox(
              height: 176.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearbyStations.length,
                separatorBuilder: (_, __) => 12.horizontalSpace,
                itemBuilder: (context, index) {
                  final station = nearbyStations[index];
                  return SizedBox(
                    width: 300.w,
                    height: 176.h,
                    child: _stationCard(context, station, index),
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

  Widget _stationCard(
    BuildContext context,
    HubcoLocationEntity station,
    int index,
  ) {
    final distances = ['0.8 km', '1.2 km', '2.1 km', '3.4 km'];
    final driveTimes = ['8 min drive', '12 min drive', '18 min drive', '24 min drive'];

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () => context.push('/station-detail', extra: station),
        borderRadius: BorderRadius.circular(20.r),
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: _mapHomeCardBg,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: _mapHomeGreen,
                      size: 22.sp,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        distances[index % distances.length],
                        color: _mapHomeGreen,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                      ),
                      2.verticalSpace,
                      AppText(
                        driveTimes[index % driveTimes.length],
                        color: _mapHomeTextMuted,
                        fontSize: FontSizes.font10Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ],
                  ),
                ],
              ),
              10.verticalSpace,
              AppText(
                station.name,
                color: _mapHomeTextDark,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              4.verticalSpace,
              AppText(
                'Super Fast • CCS2 • 150kW',
                color: _mapHomeTextMuted,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
              ),
              const Spacer(),
              Row(
                children: [
                  _portIndicatorBadge('1', isActive: true),
                  6.horizontalSpace,
                  _portIndicatorBadge('2', isActive: true),
                  6.horizontalSpace,
                  _portIndicatorBadge('+3', isActive: false),
                  const Spacer(),
                  Material(
                    color: AppColors.transparentColor,
                    child: InkWell(
                      onTap: () => context.push('/bookings'),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Ink(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: _mapHomeGreenBright,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: AppText(
                          'Book',
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                      ),
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

  Widget _portIndicatorBadge(String label, {required bool isActive}) {
    return Container(
      width: 28.w,
      height: 28.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? _mapHomeGreenBright.withValues(alpha: 0.18)
            : AppColors.shimmerGreyColor,
        shape: BoxShape.circle,
      ),
      child: AppText(
        label,
        color: isActive ? _mapHomeGreen : _mapHomeTextMuted,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight700,
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  const _MapFloatingButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      elevation: 4,
      shadowColor: AppColors.blackColor.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
      ),
    );
  }
}