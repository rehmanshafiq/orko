import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/constants/charging_stations.dart';
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
  /// 100% state of charge = 380 km usable range.
  static const double _kmPerPercentCharge = 3.8;

  /// Multiplier applied to great-circle distance to approximate road distance.
  static const double _roadFactor = 1.15;

  /// Per-route planning strategies. Index 0 = Fastest, index 1 = Economical.
  static const List<_RouteStrategy> _strategies = <_RouteStrategy>[
    _RouteStrategy(
      label: 'Fastest Route',
      maxStops: 2,
      avgSpeedKmh: 95,
      departBatteryPct: 80,
      ratePerKwh: 45,
      kwhPerPct: 0.7,
      stopChargeMinPerPct: 0.7,
    ),
    _RouteStrategy(
      label: 'Most Economical',
      maxStops: 3,
      avgSpeedKmh: 80,
      departBatteryPct: 65,
      ratePerKwh: 38,
      kwhPerPct: 0.7,
      stopChargeMinPerPct: 0.55,
    ),
  ];

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

  /// Cached plan per route. Index aligned with [_strategies].
  final List<_TripPlan?> _routePlans = <_TripPlan?>[null, null];

  Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();

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
  void initState() {
    super.initState();
    _startLocationController.addListener(_onLocationChanged);
    _endLocationController.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _startLocationController
      ..removeListener(_onLocationChanged)
      ..dispose();
    _endLocationController
      ..removeListener(_onLocationChanged)
      ..dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    if (!_tripPlanned) return;
    setState(_recomputeAllPlans);
    _fitMapToCurrentRoute();
  }

  void _onPlanTrip() {
    setState(() {
      _tripPlanned = true;
      _expandedChargingStopIndex = null;
      _recomputeAllPlans();
    });
    _fitMapToCurrentRoute();
  }

  void _onRouteSelected(int index) {
    if (_selectedRouteIndex == index) return;
    setState(() {
      _selectedRouteIndex = index;
      _expandedChargingStopIndex = null;
    });
    _fitMapToCurrentRoute();
  }

  /// Recomputes [_TripPlan] for both route strategies based on the current
  /// location field values + battery sliders.
  void _recomputeAllPlans() {
    for (var i = 0; i < _strategies.length; i++) {
      _routePlans[i] = _buildPlan(_strategies[i]);
    }
  }

  _TripPlan? _buildPlan(_RouteStrategy strategy) {
    final start = HubcoChargingStations.resolveCity(
          _startLocationController.text,
        ) ??
        const GeoPoint(name: 'Karachi', latitude: 24.8607, longitude: 67.0011);
    final end = HubcoChargingStations.resolveCity(
          _endLocationController.text,
        ) ??
        const GeoPoint(
            name: 'Islamabad', latitude: 33.6844, longitude: 73.0479);

    final stops = HubcoChargingStations.stopsAlongRoute(
      startLat: start.latitude,
      startLng: start.longitude,
      endLat: end.latitude,
      endLng: end.longitude,
      maxStops: strategy.maxStops,
    );

    final waypoints = <_LatLngNamed>[
      _LatLngNamed(start.name, start.latitude, start.longitude),
      ...stops.map(
        (s) => _LatLngNamed(s.name, s.latitude, s.longitude),
      ),
      _LatLngNamed(end.name, end.latitude, end.longitude),
    ];

    var totalKm = 0.0;
    for (var i = 0; i < waypoints.length - 1; i++) {
      totalKm += HubcoChargingStations.distanceKm(
        waypoints[i].lat,
        waypoints[i].lng,
        waypoints[i + 1].lat,
        waypoints[i + 1].lng,
      );
    }
    totalKm *= _roadFactor;

    final chargeInfo = <_StopChargeInfo>[];
    var currentBattery = _currentBatteryPercent;
    var totalChargeMinutes = 0;
    var totalCostPkr = 0;

    for (var i = 0; i < stops.length; i++) {
      final segmentKm = HubcoChargingStations.distanceKm(
            waypoints[i].lat,
            waypoints[i].lng,
            waypoints[i + 1].lat,
            waypoints[i + 1].lng,
          ) *
          _roadFactor;
      final batteryUsedPct = (segmentKm / _kmPerPercentCharge);
      final arrivePct = (currentBattery - batteryUsedPct).clamp(5.0, 100.0);
      final departPct = strategy.departBatteryPct
          .toDouble()
          .clamp(arrivePct + 10, 95.0);
      final chargedPct = (departPct - arrivePct).clamp(0.0, 100.0);
      final stopMinutes = (chargedPct * strategy.stopChargeMinPerPct).round();
      final stopCost =
          (chargedPct * strategy.kwhPerPct * strategy.ratePerKwh).round();

      chargeInfo.add(
        _StopChargeInfo(
          arrivePct: arrivePct.round(),
          departPct: departPct.round(),
          minutes: stopMinutes,
          costPkr: stopCost,
        ),
      );

      totalChargeMinutes += stopMinutes;
      totalCostPkr += stopCost;
      currentBattery = departPct;
    }

    final drivingHours = totalKm / strategy.avgSpeedKmh;
    final totalMinutes =
        (drivingHours * 60).round() + totalChargeMinutes;
    final co2SavedKg = (totalKm * 0.12).round();

    return _TripPlan(
      strategy: strategy,
      start: start,
      end: end,
      stops: stops,
      waypoints: waypoints,
      chargeInfo: chargeInfo,
      distanceKm: totalKm,
      duration: Duration(minutes: totalMinutes),
      costPkr: totalCostPkr,
      co2SavedKg: co2SavedKg,
    );
  }

  _TripPlan? get _currentPlan => _routePlans[_selectedRouteIndex];

  Future<void> _fitMapToCurrentRoute() async {
    final plan = _currentPlan;
    if (plan == null || plan.waypoints.length < 2) return;
    if (!_mapControllerCompleter.isCompleted) return;
    final controller = await _mapControllerCompleter.future;
    final bounds = _boundsFor(plan.waypoints);
    await controller
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  LatLngBounds _boundsFor(List<_LatLngNamed> points) {
    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLng = points.first.lng;
    var maxLng = points.first.lng;
    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatPkr(int amount) => 'PKR $amount';

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
              onPress: _onPlanTrip,
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
              onChanged: (v) {
                setState(() {
                  _currentBatteryPercent = v;
                  if (_tripPlanned) _recomputeAllPlans();
                });
              },
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
              onChanged: (v) {
                setState(() {
                  _targetArrivalBatteryPercent = v;
                  if (_tripPlanned) _recomputeAllPlans();
                });
              },
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
    final fastest = _routePlans[0];
    final econ = _routePlans[1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Route Options'),
        10.verticalSpace,
        _routeOptionCard(
          context,
          routeIndex: 0,
          title: _strategies[0].label,
          subtitle: fastest == null
              ? '—'
              : '${fastest.distanceKm.round()} km • ${_formatDuration(fastest.duration)}',
          stops: '${fastest?.stops.length ?? 0}',
          cost: _formatPkr(fastest?.costPkr ?? 0),
          co2: '${fastest?.co2SavedKg ?? 0} kg',
          leadingIcon: Icons.show_chart_rounded,
          leadingIconColor: AppColors.whiteColor,
          leadingBgColor: AppColors.ratingStarColor,
        ),
        8.verticalSpace,
        _routeOptionCard(
          context,
          routeIndex: 1,
          title: _strategies[1].label,
          subtitle: econ == null
              ? '—'
              : '${econ.distanceKm.round()} km • ${_formatDuration(econ.duration)}',
          stops: '${econ?.stops.length ?? 0}',
          cost: _formatPkr(econ?.costPkr ?? 0),
          co2: '${econ?.co2SavedKg ?? 0} kg',
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
      onTap: () => _onRouteSelected(routeIndex),
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
    final plan = _currentPlan;
    final routePoints = plan == null
        ? const <LatLng>[]
        : plan.waypoints.map((p) => LatLng(p.lat, p.lng)).toList();

    final initialTarget = routePoints.isEmpty
        ? const LatLng(30.3753, 69.3451)
        : LatLng(
            routePoints
                    .map((p) => p.latitude)
                    .reduce((a, b) => a + b) /
                routePoints.length,
            routePoints
                    .map((p) => p.longitude)
                    .reduce((a, b) => a + b) /
                routePoints.length,
          );

    final markers = <Marker>{
      if (routePoints.isNotEmpty)
        Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: plan?.start.name ?? 'Start'),
        ),
      if (routePoints.length > 1)
        Marker(
          markerId: const MarkerId('end'),
          position: routePoints.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(title: plan?.end.name ?? 'Destination'),
        ),
      if (plan != null)
        for (var i = 0; i < plan.stops.length; i++)
          Marker(
            markerId: MarkerId('stop-$i'),
            position: LatLng(
              plan.stops[i].latitude,
              plan.stops[i].longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: plan.stops[i].name,
              snippet: plan.stops[i].address,
            ),
          ),
    };

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
                key: ValueKey(
                  'trip-map-${plan?.strategy.label ?? '_'}-${routePoints.length}',
                ),
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 6.5,
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
                onMapCreated: (controller) {
                  if (!_mapControllerCompleter.isCompleted) {
                    _mapControllerCompleter.complete(controller);
                  } else {
                    _mapControllerCompleter =
                        Completer<GoogleMapController>()..complete(controller);
                  }
                  _fitMapToCurrentRoute();
                },
                markers: markers,
                polylines: {
                  if (routePoints.length > 1)
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
              plan?.start.name ?? 'Start',
            ),
          ),
          if (plan != null)
            for (var i = 0; i < plan.stops.length; i++)
              Positioned(
                top: (42 + (i * 24)).h,
                left: (74 + (i * 18)).w,
                child: _mapLabelChip(context, 'Stop ${i + 1}'),
              ),
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: _mapLabelChip(context, plan?.end.name ?? 'Destination'),
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

  Widget _chargingStopsSection(BuildContext context) {
    final ui = AppUiColors.of(context);
    final lineColor =
        AppColors.primaryDarkColor.withValues(alpha: ui.isLight ? 0.42 : 0.72);
    final plan = _currentPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, 'Charging Stops'),
        14.verticalSpace,
        if (plan == null)
          AppText(
            'Plan a trip to see charging stops along your route.',
            color: ui.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
          )
        else
          _chargingStopsTimeline(
            context,
            plan: plan,
            lineColor: lineColor,
          ),
      ],
    );
  }

  Widget _routeSuggestionCard(BuildContext context) {
    final ui = AppUiColors.of(context);
    final fastest = _routePlans[0];
    final econ = _routePlans[1];
    final saving = (fastest != null && econ != null)
        ? (fastest.costPkr - econ.costPkr)
        : 0;
    final hasMeaningfulSaving = saving > 0;
    final message = hasMeaningfulSaving
        ? 'Consider the economical route to save PKR $saving on the fastest route for a more enjoyable journey with better amenities.'
        : 'Both routes are similar in cost. Pick the one that best fits your schedule.';

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
                  message,
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
    required _TripPlan plan,
    required Color lineColor,
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
      return Expanded(child: connector());
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

    Widget railColumn({required List<Widget> children}) {
      return Container(
        width: rail,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      );
    }

    Widget connectorRow() {
      return Row(
        children: [
          Container(
            width: rail,
            alignment: Alignment.center,
            child: connector(height: 14.h),
          ),
          10.horizontalSpace,
          Expanded(child: Container()),
        ],
      );
    }

    final children = <Widget>[];

    children.add(
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            railColumn(
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
            10.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    plan.start.name,
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                  4.verticalSpace,
                  AppText(
                    'Starting point • ${_currentBatteryPercent.round()}% battery',
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
    );

    for (var i = 0; i < plan.stops.length; i++) {
      final station = plan.stops[i];
      final info = plan.chargeInfo[i];
      children
        ..add(connectorRow())
        ..add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                railColumn(
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
                10.horizontalSpace,
                Expanded(
                  child: _chargingStopCard(
                    context,
                    stopIndex: i,
                    station: station,
                    info: info,
                  ),
                ),
              ],
            ),
          ),
        );
    }

    children
      ..add(connectorRow())
      ..add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              railColumn(
                children: [
                  flexibleConnector(),
                  circleNode(
                    backgroundColor: AppColors.primaryLightColor,
                    child: Icon(Icons.navigation_rounded,
                        size: 11.sp, color: AppColors.whiteColor),
                  ),
                ],
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      plan.end.name,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      'Destination • ${_targetArrivalBatteryPercent.round()}% battery remaining',
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
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _chargingStopCard(
    BuildContext context, {
    required int stopIndex,
    required HubcoLocationEntity station,
    required _StopChargeInfo info,
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
                      station.name,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      station.address,
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
                  value: '${info.arrivePct}%',
                  valueColor: AppColors.ratingStarColor,
                ),
              ),
              Expanded(
                child: _chargingStopMetric(
                  context,
                  label: 'Depart',
                  value: '${info.departPct}%',
                  valueColor: AppColors.primaryDarkColor,
                ),
              ),
              Expanded(
                child: _chargingStopMetric(
                  context,
                  label: 'Time',
                  value: '${info.minutes} min',
                  valueColor: ui.textPrimary,
                ),
              ),
              Expanded(
                child: _chargingStopMetric(
                  context,
                  label: 'Cost',
                  value: _formatPkr(info.costPkr),
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
                      station: station,
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
    required HubcoLocationEntity station,
  }) {
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
    final plan = _currentPlan;
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
                  value: plan == null ? '—' : '${plan.distanceKm.round()} km',
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: _tripSummaryMetric(
                  context,
                  icon: Icons.schedule_rounded,
                  label: 'Duration',
                  value: plan == null ? '—' : _formatDuration(plan.duration),
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
                  value: '${plan?.stops.length ?? 0}',
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: _tripSummaryMetric(
                  context,
                  icon: Icons.attach_money_rounded,
                  label: 'Total Cost',
                  value: _formatPkr(plan?.costPkr ?? 0),
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
                    "You'll save ${plan?.co2SavedKg ?? 0} kg CO₂ compared to petrol vehicles",
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

/// Defines how a route option (Fastest / Economical) is planned.
class _RouteStrategy {
  const _RouteStrategy({
    required this.label,
    required this.maxStops,
    required this.avgSpeedKmh,
    required this.departBatteryPct,
    required this.ratePerKwh,
    required this.kwhPerPct,
    required this.stopChargeMinPerPct,
  });

  final String label;
  final int maxStops;
  final double avgSpeedKmh;
  final int departBatteryPct;
  final double ratePerKwh;
  final double kwhPerPct;
  final double stopChargeMinPerPct;
}

/// Computed plan for a single route option.
class _TripPlan {
  const _TripPlan({
    required this.strategy,
    required this.start,
    required this.end,
    required this.stops,
    required this.waypoints,
    required this.chargeInfo,
    required this.distanceKm,
    required this.duration,
    required this.costPkr,
    required this.co2SavedKg,
  });

  final _RouteStrategy strategy;
  final GeoPoint start;
  final GeoPoint end;
  final List<HubcoLocationEntity> stops;
  final List<_LatLngNamed> waypoints;
  final List<_StopChargeInfo> chargeInfo;
  final double distanceKm;
  final Duration duration;
  final int costPkr;
  final int co2SavedKg;
}

class _StopChargeInfo {
  const _StopChargeInfo({
    required this.arrivePct,
    required this.departPct,
    required this.minutes,
    required this.costPkr,
  });

  final int arrivePct;
  final int departPct;
  final int minutes;
  final int costPkr;
}

class _LatLngNamed {
  const _LatLngNamed(this.name, this.lat, this.lng);

  final String name;
  final double lat;
  final double lng;
}
