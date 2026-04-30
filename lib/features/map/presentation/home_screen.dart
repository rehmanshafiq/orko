import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _center = LatLng(24.8607, 67.0011);
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#101828"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#101828"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1f2937"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1f2937"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#243244"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2f3f55"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2b3a"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1f2937"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b1220"}]}
]
''';

  GoogleMapController? _mapController;

  /// True only after the dark style has been confirmed painted.
  /// The black cover overlay is shown whenever this is false,
  /// hiding any white flash from the Google Maps SDK.
  bool _mapReady = false;

  Set<Marker> _markers = const <Marker>{};
  List<HubcoLocationEntity> _locations = const [];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Map callbacks ─────────────────────────────────────────────────────────

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // Cover → apply style → reveal. One-time setup on first load.
    if (mounted) setState(() => _mapReady = false);
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    await controller.setMapStyle(_darkMapStyle);
    if (!mounted) return;

    setState(() => _mapReady = true);
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

    // Step 3 ── Update markers. The SDK flashes white here — it's hidden.
    setState(() {
      _locations = locations;
      _markers = locations.map(_toMarker).toSet();
    });

    // Step 4 ── Reapply dark style; the SDK reverted it on redraw.
    await _mapController?.setMapStyle(_darkMapStyle);
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
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
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
                    child: ColoredBox(color: AppColors.blackColor),
                  ),

                // ── UI Overlay ─────────────────────────────────────────────
                SafeArea(
                  child: Column(
                    children: [
                      10.verticalSpace,
                      Padding(
                        padding: AppUtils.horizontal16Padding,
                        child: _buildTopActions(),
                      ),
                      if (errorMessage != null) ...[
                        8.verticalSpace,
                        Padding(
                          padding: AppUtils.horizontal16Padding,
                          child: _buildErrorBanner(errorMessage),
                        ),
                      ],
                      const Spacer(),
                      _buildBottomSheet(),
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

  Widget _buildErrorBanner(String message) {
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
        color: AppColors.whiteColor,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: AppUtils.homeTopSearchPadding,
            decoration: BoxDecoration(
              color: AppColors.greyColor.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppColors.whiteColor.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.whiteColor.withValues(alpha: 0.4),
                  size: 22,
                ),
                8.horizontalSpace,
                Expanded(
                  child: AppText(
                    'Search stations or locations',
                    color: AppColors.whiteColor.withValues(alpha: 0.4),
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                ),
                8.horizontalSpace,
                _topActionIcon(
                  Icons.tune_rounded,
                  isPrimary: true,
                  isCompact: true,
                ),
              ],
            ),
          ),
        ),
        10.horizontalSpace,
        _topActionIcon(Icons.notifications_none_rounded),
      ],
    );
  }

  Widget _topActionIcon(
      IconData icon, {
        bool isPrimary = false,
        bool isCompact = false,
      }) {
    return Container(
      height: isCompact ? 30.h : 52.h,
      width: isCompact ? 30.w : 52.w,
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primaryDarkColor
            : AppColors.greyColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isPrimary
              ? AppColors.primaryDarkColor
              : AppColors.whiteColor.withValues(alpha: 0.12),
        ),
      ),
      child: Icon(
        icon,
        size: isCompact ? 15 : 26,
        color: AppColors.whiteColor,
      ),
    );
  }

  Widget _buildBottomSheet() {
    final nearbyStations = _locations.toList();

    return Container(
      padding: AppUtils.homeBottomSheetPadding,
      decoration: BoxDecoration(
        color: AppColors.blackColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            child: Container(
              height: 3.h,
              width: 26.w,
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          12.verticalSpace,
          AppText(
            'Nearby Stations',
            color: AppColors.whiteColor,
            fontSize: FontSizes.font24Sp,
            fontWeight: FontWeights.weight700,
          ),
          10.verticalSpace,
          Row(
            children: [
              _chip('Available Now', isActive: true),
              8.horizontalSpace,
              _chip('DC Fast'),
              8.horizontalSpace,
              _chip('AC Level 2'),
            ],
          ),
          12.verticalSpace,
          if (nearbyStations.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: AppText(
                'No stations available',
                color: AppColors.whiteColor.withValues(alpha: 0.75),
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
            )
          else
            SizedBox(
              height: 110.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearbyStations.length,
                separatorBuilder: (_, __) => 8.horizontalSpace,
                itemBuilder: (context, index) {
                  final station = nearbyStations[index];
                  return SizedBox(
                    width: 176.w,
                    child: _stationCard(
                      context,
                      station.name,
                      station.status ? 'Available' : 'Unavailable',
                      station.address,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Marker _toMarker(HubcoLocationEntity station) {
    return Marker(
      markerId: MarkerId(station.id.toString()),
      position: LatLng(station.latitude, station.longitude),
      infoWindow: InfoWindow(title: station.name),
      onTap: () => _showStationDialog(station),
    );
  }

  Future<void> _showStationDialog(HubcoLocationEntity station) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fieldBackgroundColor,
        title: AppText(
          station.name,
          color: AppColors.whiteColor,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              "Address: ${station.address}",
              color: AppColors.whiteColor.withValues(alpha: 0.8),
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
            8.verticalSpace,
            AppText(
              'Lat: ${station.latitude}, Lng: ${station.longitude}',
              color: AppColors.whiteColor.withValues(alpha: 0.75),
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
            ),
            6.verticalSpace,
            AppText(
              station.status ? 'Status: Active' : 'Status: Inactive',
              color: station.status
                  ? AppColors.primaryDarkColor
                  : Colors.redAccent,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight600,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: AppText(
              'Close',
              color: AppColors.whiteColor.withValues(alpha: 0.8),
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool isActive = false}) {
    return Container(
      padding: AppUtils.homeFilterChipPadding,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryDarkColor.withValues(alpha: 0.22)
            : AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive
              ? AppColors.primaryDarkColor
              : AppColors.whiteColor.withValues(alpha: 0.12),
        ),
      ),
      child: AppText(
        text,
        color: isActive
            ? AppColors.primaryDarkColor
            : AppColors.whiteColor.withValues(alpha: 0.8),
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }

  Widget _stationCard(
    BuildContext context,
    String title,
    String availability,
    String price,
  ) {
    return Container(
      padding: AppUtils.homeStationCardPadding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            color: AppColors.whiteColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight600,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          4.verticalSpace,
          AppText(
            availability,
            color: AppColors.primaryDarkColor,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight500,
          ),
          6.verticalSpace,
          AppText(
            price,
            color: AppColors.whiteColor.withValues(alpha: 0.75),
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}