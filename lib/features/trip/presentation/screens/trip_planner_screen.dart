import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class TripPlannerScreen extends StatelessWidget {
  const TripPlannerScreen({super.key});

  static const LatLng _mapCenter = LatLng(32.1156, 73.2707);
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
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b1220"}]}
]
''';

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: ListView(
          padding: AppUtils.horizontal16Padding,
          children: [
            10.verticalSpace,
            _header(context),
            16.verticalSpace,
            _locationField(context, 'Lahore', isStart: true),
            8.verticalSpace,
            _locationField(context, 'Islamabad', isStart: false),
            14.verticalSpace,
            _sectionTitle(context, 'EV Details'),
            10.verticalSpace,
            _evDetailsCard(context),
            12.verticalSpace,
            PrimaryButtonWidget(
              text: 'Plan Trip',
              onPress: () {},
              buttonColor: AppColors.primaryDarkColor,
              fontWeight: FontWeights.weight700,
              fontSize: FontSizes.font14Sp,
              cornerRadius: 8.r,
            ),
            12.verticalSpace,
            _mapCard(context),
            12.verticalSpace,
            _sectionTitle(context, 'Suggested Stops'),
            8.verticalSpace,
            _stopCard(
              context,
              title: 'Stop 1: HCL Hub Kala Shah Kaku',
              subtitle: '45 min charge, Rs 450 estimated',
            ),
            8.verticalSpace,
            _stopCard(
              context,
              title: 'Stop 2: HCL Hub Rawat',
              subtitle: '30 min charge, Rs 300 estimated',
            ),
            12.verticalSpace,
            _sectionTitle(context, 'Trip Summary'),
            8.verticalSpace,
            _tripSummaryCard(context),
            22.verticalSpace,
            _mapListToggle(context),
            8.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        Icon(Icons.arrow_back_rounded, color: ui.textPrimary, size: 20.sp),
        8.horizontalSpace,
        AppText(
          'Trip Planner',
          color: ui.textPrimary,
          fontSize: FontSizes.font22Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }

  Widget _locationField(BuildContext context, String value, {required bool isStart}) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 14.sp,
            color: isStart ? AppColors.primaryDarkColor : AppColors.removeColor,
          ),
          8.horizontalSpace,
          AppText(
            value,
            color: ui.textPrimary.withValues(alpha: 0.9),
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return AppText(
      text,
      color: AppUiColors.of(context).textPrimary,
      fontSize: FontSizes.font16Sp,
      fontWeight: FontWeights.weight700,
    );
  }

  Widget _evDetailsCard(BuildContext context) {
    return Row(
      children: [
        _metric(context, icon: Icons.battery_6_bar_rounded, value: '60%', label: 'current charge'),
        12.horizontalSpace,
        _metric(context, icon: Icons.electric_car_rounded, value: 'Tesla', label: 'Model 3'),
        12.horizontalSpace,
        _metric(context, icon: Icons.route_rounded, value: '280 km', label: 'range'),
      ],
    );
  }

  Widget _metric(BuildContext context, {required IconData icon, required String value, required String label}) {
    final ui = AppUiColors.of(context);
    return Expanded(
      child: Container(
        padding: AppUtils.horizontal8Vertical4Padding,
        decoration: BoxDecoration(
          color: ui.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: ui.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryLightColor, size: 14.sp),
                4.horizontalSpace,
                AppText(
                  value,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ],
            ),
            2.verticalSpace,
            AppText(
              label,
              color: ui.textMuted,
              fontSize: FontSizes.font8Sp,
              fontWeight: FontWeights.weight400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapCard(BuildContext context) {
    final ui = AppUiColors.of(context);
    final routePoints = <LatLng>[
      const LatLng(32.0945, 73.1945),
      const LatLng(32.1245, 73.2380),
      const LatLng(32.1442, 73.2868),
    ];

    return Container(
      height: 132.h,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _mapCenter,
                  zoom: 9.8,
                ),
                style: ui.isLight ? null : _darkMapStyle,
                compassEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomGesturesEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('start'),
                    position: routePoints.first,
                    icon: BitmapDescriptor.defaultMarker
                  ),
                  Marker(
                    markerId: const MarkerId('stop-1'),
                    position: routePoints[1],
                    icon: BitmapDescriptor.defaultMarker
                  ),
                  Marker(
                    markerId: const MarkerId('stop-2'),
                    position: routePoints[2],
                    icon: BitmapDescriptor.defaultMarker
                  ),
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('trip-route'),
                    points: routePoints,
                    color: AppColors.primaryDarkColor,
                    width: 4,
                  ),
                },
              ),
            ),
          ),
          Positioned(
            top: 10.h,
            left: 10.w,
            child: _mapLabelChip(
              context,
              'Start',
            ),
          ),
          Positioned(
            top: 42.h,
            left: 74.w,
            child: _mapLabelChip(context, 'Stop 1'),
          ),
          Positioned(
            top: 68.h,
            left: 120.w,
            child: _mapLabelChip(context, 'Stop 2'),
          ),
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: _mapLabelChip(context, 'Street'),
          ),
        ],
      ),
    );
  }

  Widget _mapLabelChip(BuildContext context, String text) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: ui.isLight
            ? AppColors.whiteColor.withValues(alpha: 0.85)
            : AppColors.blackColor.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: AppText(
        text,
        color: ui.textPrimary.withValues(alpha: 0.88),
        fontSize: FontSizes.font8Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }

  Widget _stopCard(BuildContext context, {required String title, required String subtitle}) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.primaryDarkColor),
      ),
      child: Row(
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: const BoxDecoration(
              color: AppColors.primaryDarkColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, size: 11.sp, color: AppColors.whiteColor),
          ),
          8.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font10Sp,
                  fontWeight: FontWeights.weight600,
                ),
                2.verticalSpace,
                AppText(
                  subtitle,
                  color: ui.textMuted,
                  fontSize: FontSizes.font8Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripSummaryCard(BuildContext context) {
    return Row(
      children: [
        _summaryItem(context, title: 'Total Distance', value: '380 km'),
        _summaryItem(context, title: 'Total Time', value: '4h 20min'),
        _summaryItem(context, title: 'Total Charging Cost', value: 'Rs 750'),
      ],
    );
  }

  Widget _summaryItem(BuildContext context, {required String title, required String value}) {
    final ui = AppUiColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 5.sp, color: ui.textMuted),
              4.horizontalSpace,
              Expanded(
                child: AppText(
                  title,
                  color: ui.textMuted,
                  fontSize: FontSizes.font8Sp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          4.verticalSpace,
          AppText(
            value,
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight600,
          ),
        ],
      ),
    );
  }

  Widget _mapListToggle(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          'Map View',
          color: AppColors.primaryDarkColor,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight600,
        ),
        8.horizontalSpace,
        Container(
          width: 30.w,
          height: 16.h,
          padding: AppUtils.all4Padding,
          decoration: BoxDecoration(
            color: AppColors.primaryDarkColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: const BoxDecoration(
                color: AppColors.primaryLightColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        8.horizontalSpace,
        AppText(
          'List View',
          color: ui.textSecondary,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight500,
        ),
      ],
    );
  }
}
