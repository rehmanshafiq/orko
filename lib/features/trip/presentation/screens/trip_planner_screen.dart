import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/presentation/screens/book_a_slot_screen.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/charging_station_detail_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  static const LatLng _mapCenter = LatLng(32.1156, 73.2707);

  /// 100% state of charge = 380 km usable range.
  static const double _kmPerPercentCharge = 3.8;

  final TextEditingController _startLocationController =
      TextEditingController(text: 'Karachi');
  final TextEditingController _endLocationController =
      TextEditingController(text: 'Islamabad');

  double _currentBatteryPercent = 60;
  double _targetArrivalBatteryPercent = 20;

  bool _tripPlanned = false;
  int _selectedRouteIndex = 0;

  /// At most one charging-stop card expanded (accordion).
  int? _expandedChargingStopIndex;

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    super.dispose();
  }

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
            _locationField(context,
                controller: _startLocationController, isStart: true),
            8.verticalSpace,
            _locationField(context,
                controller: _endLocationController, isStart: false),
            14.verticalSpace,
            _sectionTitle(context, 'EV Details'),
            10.verticalSpace,
            _evDetailsCard(context),
            14.verticalSpace,
            _batteryChargeSliders(context),
            14.verticalSpace,
            PrimaryButtonWidget(
              text: 'Plan Trip',
              onPress: () => setState(() => _tripPlanned = true),
              buttonColor: AppColors.primaryDarkColor,
              fontWeight: FontWeights.weight700,
              fontSize: FontSizes.font14Sp,
              cornerRadius: 8.r,
            ),
            if (_tripPlanned) ...[
              16.verticalSpace,
              _routeOptionsSection(context),
              12.verticalSpace,
              _mapCard(context),
              16.verticalSpace,
              _chargingStopsSection(context),
              16.verticalSpace,
              _routeSuggestionCard(context),
              22.verticalSpace,
              _sectionTitle(context, 'Trip Summary'),
              8.verticalSpace,
              _tripSummaryCard(context),
              22.verticalSpace,
            ],
            24.verticalSpace,
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

  Widget _locationField(
    BuildContext context, {
    required TextEditingController controller,
    required bool isStart,
  }) {
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
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction:
                  isStart ? TextInputAction.next : TextInputAction.done,
              keyboardType: TextInputType.streetAddress,
              style: TextStyle(
                color: ui.textPrimary.withValues(alpha: 0.9),
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
              cursorColor: AppColors.primaryDarkColor,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _metric(context,
                icon: Icons.electric_car_rounded,
                value: 'BYD',
                label: 'Atto 3'),
            8.horizontalSpace,
            _metric(context,
                icon: Icons.route_rounded, value: '280 km', label: 'range'),
          ],
        ),
        12.verticalSpace,
        Row(
          children: [
            _metric(
              context,
              icon: Icons.battery_6_bar_rounded,
              value: '${_currentBatteryPercent.round()}%',
              label: 'current charge',
            ),
          ],
        ),
      ],
    );
  }

  Widget _batteryChargeSliders(BuildContext context) {
    final ui = AppUiColors.of(context);
    final usableRangeKm =
        (_currentBatteryPercent * _kmPerPercentCharge).round();

    return Container(
      padding: AppUtils.horizontal8Vertical8Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Current Battery',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                ),
              ),
              8.horizontalSpace,
              AppText(
                '${_currentBatteryPercent.round()}%',
                color: AppColors.primaryDarkColor,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
          6.verticalSpace,
          _batterySliderTheme(
            context,
            child: Slider(
              value: _currentBatteryPercent.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => setState(() => _currentBatteryPercent = v),
            ),
          ),
          4.verticalSpace,
          AppText(
            '≈ $usableRangeKm km usable range (100% = 380 km)',
            color: ui.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
          ),
          18.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Target Arrival Battery',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                ),
              ),
              8.horizontalSpace,
              AppText(
                '${_targetArrivalBatteryPercent.round()}%',
                color: AppColors.primaryDarkColor,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
          6.verticalSpace,
          _batterySliderTheme(
            context,
            child: Slider(
              value: _targetArrivalBatteryPercent.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) =>
                  setState(() => _targetArrivalBatteryPercent = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _batterySliderTheme(BuildContext context, {required Widget child}) {
    final ui = AppUiColors.of(context);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4.h,
        activeTrackColor: AppColors.primaryDarkColor,
        inactiveTrackColor: ui.progressTrack,
        thumbColor: AppColors.primaryDarkColor,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 10.r,
          elevation: 0,
          pressedElevation: 0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
        overlayColor: WidgetStateColor.resolveWith(
          (_) => AppColors.primaryDarkColor.withValues(alpha: 0.16),
        ),
      ),
      child: child,
    );
  }

  Widget _routeOptionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Route Options'),
        10.verticalSpace,
        _routeOptionCard(
          context,
          routeIndex: 0,
          title: 'Fastest Route',
          subtitle: '1214 km • 13h 0m',
          stops: '2',
          cost: 'PKR 3200',
          co2: '145 kg',
          leadingIcon: Icons.show_chart_rounded,
          leadingIconColor: AppColors.whiteColor,
          leadingBgColor: AppColors.ratingStarColor,
        ),
        8.verticalSpace,
        _routeOptionCard(
          context,
          routeIndex: 1,
          title: 'Most Economical',
          subtitle: '1198 km • 14h 0m',
          stops: '3',
          cost: 'PKR 2650',
          co2: '148 kg',
          leadingIcon: Icons.attach_money_rounded,
          leadingIconColor: AppColors.primaryDarkColor,
          leadingBgColor: AppColors.primaryLightColor.withValues(alpha: 0.55),
        ),
      ],
    );
  }

  Widget _routeOptionCard(
    BuildContext context, {
    required int routeIndex,
    required String title,
    required String subtitle,
    required String stops,
    required String cost,
    required String co2,
    required IconData leadingIcon,
    required Color leadingIconColor,
    required Color leadingBgColor,
  }) {
    final ui = AppUiColors.of(context);
    final selected = _selectedRouteIndex == routeIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedRouteIndex = routeIndex),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: AppUtils.vertical10Horizontal12Padding,
        decoration: BoxDecoration(
          color: selected ? ui.efficiencyTipBg : ui.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? AppColors.primaryDarkColor : ui.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: leadingBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child:
                      Icon(leadingIcon, color: leadingIconColor, size: 20.sp),
                ),
                10.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        color: ui.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                      ),
                      4.verticalSpace,
                      AppText(
                        subtitle,
                        color: ui.textMuted,
                        fontSize: FontSizes.font10Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  8.horizontalSpace,
                  Container(
                    padding: AppUtils.horizontal8Vertical4Padding,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: AppText(
                      'Selected',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font8Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ),
                ],
              ],
            ),
            14.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: _routeOptionMetric(
                    context,
                    label: 'Stops',
                    value: stops,
                    valueColor: ui.textPrimary,
                  ),
                ),
                Expanded(
                  child: _routeOptionMetric(
                    context,
                    label: 'Cost',
                    value: cost,
                    valueColor: AppColors.primaryDarkColor,
                  ),
                ),
                Expanded(
                  child: _routeOptionMetric(
                    context,
                    label: 'CO2 Saved',
                    value: co2,
                    valueColor: AppColors.primaryDarkColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeOptionMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textMuted,
          fontSize: FontSizes.font8Sp,
          fontWeight: FontWeights.weight400,
        ),
        4.verticalSpace,
        AppText(
          value,
          color: valueColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }

  Widget _metric(BuildContext context,
      {required IconData icon, required String value, required String label}) {
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
      height: 212.h,
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
                      icon: BitmapDescriptor.defaultMarker),
                  Marker(
                      markerId: const MarkerId('stop-1'),
                      position: routePoints[1],
                      icon: BitmapDescriptor.defaultMarker),
                  Marker(
                      markerId: const MarkerId('stop-2'),
                      position: routePoints[2],
                      icon: BitmapDescriptor.defaultMarker),
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

  String _chargingPlaceTitle(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'Karachi, Pakistan';
    if (t.contains(',')) return t;
    return '$t, Pakistan';
  }

  Widget _chargingStopsSection(BuildContext context) {
    final ui = AppUiColors.of(context);
    final lineColor =
        AppColors.primaryDarkColor.withValues(alpha: ui.isLight ? 0.42 : 0.72);
    final startRaw = _startLocationController.text.trim();
    final destRaw = _endLocationController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Charging Stops'),
        14.verticalSpace,
        _chargingStopsTimeline(
          context,
          lineColor: lineColor,
          startTitle: _chargingPlaceTitle(startRaw),
          destTitle: destRaw.isEmpty ? 'Islamabad' : destRaw,
          startBattery: _currentBatteryPercent.round(),
          destBattery: _targetArrivalBatteryPercent.round(),
        ),
      ],
    );
  }

  Widget _routeSuggestionCard(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.chargingPatternsBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: ui.chargingPatternsBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.info_outline_rounded,
              size: 15.sp,
              color: AppColors.mapPinBlueColor,
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Route Suggestions',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight700,
                ),
                4.verticalSpace,
                AppText(
                  'Consider the economical route to save PKR 550 on the scenic route for a more enjoyable journey with better amenities.',
                  color: ui.textSecondary,
                  fontSize: FontSizes.font10Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargingStopsTimeline(
    BuildContext context, {
    required Color lineColor,
    required String startTitle,
    required String destTitle,
    required int startBattery,
    required int destBattery,
  }) {
    final ui = AppUiColors.of(context);
    final rail = 38.w;
    final node = 24.w;

    Widget connector({double? height}) {
      return Center(
        child: Container(
          width: 2.w,
          height: height,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      );
    }

    Widget flexibleConnector() {
      return Expanded(
        child: connector(),
      );
    }

    Widget circleNode({
      required Color backgroundColor,
      required Widget child,
    }) {
      return Container(
        width: node,
        height: node,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: rail,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    circleNode(
                      backgroundColor: AppColors.primaryDarkColor,
                      child: Icon(Icons.location_on_rounded,
                          size: 12.sp, color: AppColors.whiteColor),
                    ),
                    4.verticalSpace,
                    flexibleConnector(),
                  ],
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      startTitle,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      'Starting point • $startBattery% battery',
                      color: ui.textMuted,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              width: rail,
              alignment: Alignment.center,
              child: connector(height: 14.h),
            ),
            10.horizontalSpace,
            Expanded(child: Container()),
          ],
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: rail,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    flexibleConnector(),
                    circleNode(
                      backgroundColor: AppColors.ratingStarColor,
                      child: Icon(Icons.bolt_rounded,
                          size: 12.sp, color: AppColors.whiteColor),
                    ),
                    flexibleConnector(),
                  ],
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: _chargingStopCard(
                  context,
                  stopIndex: 0,
                  stationName: 'HUBCO Hyderabad Station',
                  address: 'M-9 Motorway, Hyderabad',
                  arrive: '25%',
                  depart: '80%',
                  time: '35 min',
                  cost: 'PKR 1400',
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              width: rail,
              alignment: Alignment.center,
              child: connector(height: 14.h),
            ),
            10.horizontalSpace,
            Expanded(child: Container()),
          ],
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: rail,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    flexibleConnector(),
                    circleNode(
                      backgroundColor: AppColors.ratingStarColor,
                      child: Icon(Icons.bolt_rounded,
                          size: 12.sp, color: AppColors.whiteColor),
                    ),
                    flexibleConnector(),
                  ],
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: _chargingStopCard(
                  context,
                  stopIndex: 1,
                  stationName: 'HUBCO Sukkur Fast Charge',
                  address: 'National Highway N-5, Sukkur',
                  arrive: '18%',
                  depart: '85%',
                  time: '40 min',
                  cost: 'PKR 1800',
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              width: rail,
              alignment: Alignment.center,
              child: connector(height: 14.h),
            ),
            10.horizontalSpace,
            Expanded(child: Container()),
          ],
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: rail,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    flexibleConnector(),
                    circleNode(
                      backgroundColor: AppColors.primaryLightColor,
                      child: Icon(Icons.navigation_rounded,
                          size: 11.sp, color: AppColors.whiteColor),
                    ),
                  ],
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      destTitle,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      'Destination • $destBattery% battery remaining',
                      color: ui.textMuted,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chargingStopCard(
    BuildContext context, {
    required int stopIndex,
    required String stationName,
    required String address,
    required String arrive,
    required String depart,
    required String time,
    required String cost,
  }) {
    final ui = AppUiColors.of(context);
    final expanded = _expandedChargingStopIndex == stopIndex;

    void toggleAccordion() {
      setState(() {
        _expandedChargingStopIndex = expanded ? null : stopIndex;
      });
    }

    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.ratingStarColor.withValues(alpha: 0.95),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      stationName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      address,
                      color: ui.textMuted,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              4.horizontalSpace,
              GestureDetector(
                onTap: toggleAccordion,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: AppUtils.all4Padding,
                  child: Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 22.sp,
                    color: ui.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _chargingStopMetric(
                  context,
                  label: 'Arrive',
                  value: arrive,
                  valueColor: AppColors.ratingStarColor,
                ),
              ),
              Expanded(
                child: _chargingStopMetric(
                  context,
                  label: 'Depart',
                  value: depart,
                  valueColor: AppColors.primaryDarkColor,
                ),
              ),
              Expanded(
                child: _chargingStopMetric(
                  context,
                  label: 'Time',
                  value: time,
                  valueColor: ui.textPrimary,
                ),
              ),
              Expanded(
                child: _chargingStopMetric(
                  context,
                  label: 'Cost',
                  value: cost,
                  valueColor: ui.textPrimary,
                ),
              ),
            ],
          ),
          if (expanded) ...[
            14.verticalSpace,
            AppText(
              'Amenities',
              color: ui.textPrimary,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight600,
            ),
            8.verticalSpace,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chargingAmenityChip(context,
                      icon: Icons.wifi_rounded, label: 'WiFi'),
                  8.horizontalSpace,
                  _chargingAmenityChip(context,
                      icon: Icons.wc_rounded, label: 'Restroom'),
                  8.horizontalSpace,
                  _chargingAmenityChip(context,
                      icon: Icons.local_cafe_rounded, label: 'Food'),
                  8.horizontalSpace,
                  _chargingAmenityChip(context,
                      icon: Icons.shopping_bag_outlined, label: 'Shopping'),
                ],
              ),
            ),
            14.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'View Details',
                    onPress: () => _openChargingStationDetails(
                      context,
                      stopIndex: stopIndex,
                      stationName: stationName,
                      address: address,
                    ),
                    buttonWidth: double.infinity,
                    buttonHeight: 40.h,
                    cornerRadius: 8.r,
                    buttonColor: ui.cardBackground,
                    strokeColor: ui.inputBorder,
                    textColor: ui.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
                8.horizontalSpace,
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'Pre-book',
                    onPress: () => _openPreBook(context),
                    buttonWidth: double.infinity,
                    buttonHeight: 40.h,
                    cornerRadius: 8.r,
                    buttonColor: ui.cardBackground,
                    strokeColor: ui.inputBorder,
                    textColor: ui.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openChargingStationDetails(
    BuildContext context, {
    required int stopIndex,
    required String stationName,
    required String address,
  }) {
    final station = HubcoLocationEntity(
      id: stopIndex + 1,
      name: stationName,
      address: address,
      latitude: _mapCenter.latitude,
      longitude: _mapCenter.longitude,
      status: true,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChargingStationDetailScreen(station: station),
      ),
    );
  }

  void _openPreBook(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BookASlotScreen(),
      ),
    );
  }

  Widget _chargingAmenityChip(BuildContext context,
      {required IconData icon, required String label}) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.homeStationCardPadding,
      decoration: BoxDecoration(
        color: ui.vehicleStatBoxBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: ui.textPrimary),
          6.horizontalSpace,
          AppText(
            label,
            color: ui.textPrimary,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight600,
          ),
        ],
      ),
    );
  }

  Widget _chargingStopMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textMuted,
          fontSize: FontSizes.font8Sp,
          fontWeight: FontWeights.weight400,
        ),
        4.verticalSpace,
        AppText(
          value,
          color: valueColor,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _tripSummaryCard(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border:
            Border.all(color: AppColors.mapPinBlueColor.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _tripSummaryMetric(
                  context,
                  icon: Icons.near_me_outlined,
                  label: 'Distance',
                  value: '1214 km',
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: _tripSummaryMetric(
                  context,
                  icon: Icons.schedule_rounded,
                  label: 'Duration',
                  value: '13h 0m',
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _tripSummaryMetric(
                  context,
                  icon: Icons.bolt_rounded,
                  label: 'Charging Stops',
                  value: '2',
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: _tripSummaryMetric(
                  context,
                  icon: Icons.attach_money_rounded,
                  label: 'Total Cost',
                  value: 'PKR 3200',
                ),
              ),
            ],
          ),
          14.verticalSpace,
          Container(
            padding: AppUtils.vertical10Horizontal12Padding,
            decoration: BoxDecoration(
              color: ui.efficiencyTipBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 14.sp,
                  color: AppColors.primaryLightColor,
                ),
                8.horizontalSpace,
                Expanded(
                  child: AppText(
                    "You'll save 145 kg CO₂ compared to petrol vehicles",
                    color: ui.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripSummaryMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12.sp, color: AppColors.mapPinBlueColor),
            6.horizontalSpace,
            Expanded(
              child: AppText(
                label,
                color: ui.textMuted,
                fontSize: FontSizes.font8Sp,
                fontWeight: FontWeights.weight400,
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
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }
}
