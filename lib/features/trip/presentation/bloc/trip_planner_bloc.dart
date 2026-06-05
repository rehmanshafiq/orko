import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/charging_stations.dart';
import 'package:orko_hubco/features/booking/presentation/pages/book_slot_page.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/charging/presentation/page/charging_station_detail_page.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_event.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_state.dart';
import 'package:orko_hubco/features/trip/presentation/models/latlng_named_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/route_strategy_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/stop_charge_info_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';

class TripPlannerBloc extends Bloc<TripPlannerEvent, TripPlannerState> {
  TripPlannerBloc() : super(TripPlannerState.initial()) {
    _startLocationController.addListener(_onLocationChanged);
    _endLocationController.addListener(_onLocationChanged);

    on<TripPlannerLocationChanged>(_handleLocationChanged);
    on<TripPlannerPlanTripPressed>(_handlePlanTripPressed);
    on<TripPlannerRouteSelected>(_handleRouteSelected);
    on<TripPlannerBatteryChanged>(_handleBatteryChanged);
    on<TripPlannerArrivalBatteryChanged>(_handleArrivalBatteryChanged);
    on<TripPlannerChargingStopExpanded>(_handleChargingStopExpanded);
    on<TripPlannerLoadMarkerIcons>(_handleLoadMarkerIcons);
    on<TripPlannerMapCreated>(_handleMapCreated);
    on<TripPlannerFitMapRoute>(_handleFitMapRoute);
  }

  /// 100% state of charge = 380 km usable range.
  static const double kmPerPercentCharge = 3.8;

  /// Multiplier applied to great-circle distance to approximate road distance.
  static const double roadFactor = 1.15;

  /// Logical (dp) marker side. Kept smaller than the home map because the
  /// trip-planner mini-map is only ~212dp tall.
  static const double stationMarkerSize = 12;

  static const List<RouteStrategyModel> strategies = <RouteStrategyModel>[
    RouteStrategyModel(
      label: 'Fastest Route',
      maxStops: 2,
      avgSpeedKmh: 95,
      departBatteryPct: 80,
      ratePerKwh: 45,
      kwhPerPct: 0.7,
      stopChargeMinPerPct: 0.7,
    ),
    RouteStrategyModel(
      label: 'Most Economical',
      maxStops: 3,
      avgSpeedKmh: 80,
      departBatteryPct: 65,
      ratePerKwh: 38,
      kwhPerPct: 0.7,
      stopChargeMinPerPct: 0.55,
    ),
  ];

  static const String darkMapStyle = '''
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

  final TextEditingController _startLocationController =
      TextEditingController(text: 'Karachi');
  final TextEditingController _endLocationController =
      TextEditingController(text: 'Lahore');

  TextEditingController get startLocationController => _startLocationController;
  TextEditingController get endLocationController => _endLocationController;

  void _onLocationChanged() {
    add(const TripPlannerLocationChanged());
  }

  void _handleLocationChanged(
    TripPlannerLocationChanged event,
    Emitter<TripPlannerState> emit,
  ) {
    if (!state.tripPlanned) return;
    emit(state.copyWith(routePlans: _recomputeAllPlans(state)));
    add(const TripPlannerFitMapRoute());
  }

  void _handlePlanTripPressed(
    TripPlannerPlanTripPressed event,
    Emitter<TripPlannerState> emit,
  ) {
    emit(
      state.copyWith(
        tripPlanned: true,
        resetExpandedChargingStopIndex: true,
        routePlans: _recomputeAllPlans(state.copyWith(tripPlanned: true)),
      ),
    );
    add(const TripPlannerFitMapRoute());
  }

  void _handleRouteSelected(
    TripPlannerRouteSelected event,
    Emitter<TripPlannerState> emit,
  ) {
    if (state.selectedRouteIndex == event.index) return;
    emit(
      state.copyWith(
        selectedRouteIndex: event.index,
        resetExpandedChargingStopIndex: true,
      ),
    );
    add(const TripPlannerFitMapRoute());
  }

  void _handleBatteryChanged(
    TripPlannerBatteryChanged event,
    Emitter<TripPlannerState> emit,
  ) {
    final nextState = state.copyWith(currentBatteryPercent: event.value);
    emit(
      nextState.copyWith(
        routePlans: nextState.tripPlanned ? _recomputeAllPlans(nextState) : null,
      ),
    );
  }

  void _handleArrivalBatteryChanged(
    TripPlannerArrivalBatteryChanged event,
    Emitter<TripPlannerState> emit,
  ) {
    final nextState = state.copyWith(targetArrivalBatteryPercent: event.value);
    emit(
      nextState.copyWith(
        routePlans: nextState.tripPlanned ? _recomputeAllPlans(nextState) : null,
      ),
    );
  }

  void _handleChargingStopExpanded(
    TripPlannerChargingStopExpanded event,
    Emitter<TripPlannerState> emit,
  ) {
    final expanded = state.expandedChargingStopIndex == event.stopIndex;
    emit(
      state.copyWith(
        expandedChargingStopIndex: expanded ? null : event.stopIndex,
      ),
    );
  }

  Future<void> _handleLoadMarkerIcons(
    TripPlannerLoadMarkerIcons event,
    Emitter<TripPlannerState> emit,
  ) async {
    if (state.iconsLoaded) return;
    emit(state.copyWith(iconsLoaded: true));

    final stop = await _renderMarkerIcon(
      iconData: Icons.bolt_outlined,
      color: AppColors.primaryDarkColor,
      dpr: event.devicePixelRatio,
    );
    final start = await _renderMarkerIcon(
      iconData: Icons.location_on_rounded,
      color: AppColors.primaryDarkColor,
      dpr: event.devicePixelRatio,
    );
    final end = await _renderMarkerIcon(
      iconData: Icons.location_on_rounded,
      color: AppColors.removeColor,
      dpr: event.devicePixelRatio,
    );

    emit(
      state.copyWith(
        stopIcon: stop,
        startIcon: start,
        endIcon: end,
      ),
    );
  }

  void _handleMapCreated(
    TripPlannerMapCreated event,
    Emitter<TripPlannerState> emit,
  ) {
    final currentCompleter = state.mapControllerCompleter;
    Completer<GoogleMapController> nextCompleter = currentCompleter;
    if (!currentCompleter.isCompleted) {
      currentCompleter.complete(event.controller);
    } else {
      nextCompleter = Completer<GoogleMapController>()..complete(event.controller);
    }

    emit(
      state.copyWith(
        mapController: event.controller,
        mapControllerCompleter: nextCompleter,
      ),
    );
    add(const TripPlannerFitMapRoute());
  }

  Future<void> _handleFitMapRoute(
    TripPlannerFitMapRoute event,
    Emitter<TripPlannerState> emit,
  ) async {
    final plan = state.currentPlan;
    if (plan == null || plan.waypoints.length < 2) return;
    if (!state.mapControllerCompleter.isCompleted) return;
    final controller = await state.mapControllerCompleter.future;
    final bounds = _boundsFor(plan.waypoints);
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  List<TripPlanModel?> _recomputeAllPlans(TripPlannerState sourceState) {
    final plans = List<TripPlanModel?>.filled(strategies.length, null);
    for (var i = 0; i < strategies.length; i++) {
      plans[i] = _buildPlan(strategies[i], sourceState);
    }
    return plans;
  }

  TripPlanModel? _buildPlan(
    RouteStrategyModel strategy,
    TripPlannerState sourceState,
  ) {
    final start = HubcoChargingStations.resolveCity(_startLocationController.text) ??
        const GeoPoint(name: 'Karachi', latitude: 24.8607, longitude: 67.0011);
    final end = HubcoChargingStations.resolveCity(_endLocationController.text) ??
        const GeoPoint(name: 'Lahore', latitude: 33.6844, longitude: 73.0479);

    final stops = HubcoChargingStations.stopsAlongRoute(
      startLat: start.latitude,
      startLng: start.longitude,
      endLat: end.latitude,
      endLng: end.longitude,
      maxStops: strategy.maxStops,
    );

    final waypoints = <LatLngNamedModel>[
      LatLngNamedModel(start.name, start.latitude, start.longitude),
      ...stops.map((s) => LatLngNamedModel(s.name, s.latitude, s.longitude)),
      LatLngNamedModel(end.name, end.latitude, end.longitude),
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
    totalKm *= roadFactor;

    final chargeInfo = <StopChargeInfoModel>[];
    var currentBattery = sourceState.currentBatteryPercent;
    var totalChargeMinutes = 0;
    var totalCostPkr = 0;

    for (var i = 0; i < stops.length; i++) {
      final segmentKm = HubcoChargingStations.distanceKm(
            waypoints[i].lat,
            waypoints[i].lng,
            waypoints[i + 1].lat,
            waypoints[i + 1].lng,
          ) *
          roadFactor;
      final batteryUsedPct = (segmentKm / kmPerPercentCharge);
      final arrivePct = (currentBattery - batteryUsedPct).clamp(5.0, 100.0);
      final departPct = strategy.departBatteryPct.toDouble().clamp(arrivePct + 10, 95.0);
      final chargedPct = (departPct - arrivePct).clamp(0.0, 100.0);
      final stopMinutes = (chargedPct * strategy.stopChargeMinPerPct).round();
      final stopCost = (chargedPct * strategy.kwhPerPct * strategy.ratePerKwh).round();

      chargeInfo.add(
        StopChargeInfoModel(
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
    final totalMinutes = (drivingHours * 60).round() + totalChargeMinutes;
    final co2SavedKg = (totalKm * 0.12).round();

    return TripPlanModel(
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

  Future<BitmapDescriptor?> _renderMarkerIcon({
    required IconData iconData,
    required Color color,
    required double dpr,
  }) async {
    try {
      final size = stationMarkerSize * dpr;
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      final iconPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: size * 0.88,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: color,
          ),
        ),
      );
      iconPainter.layout();

      final iconOffset = Offset(
        (size - iconPainter.width) / 2,
        (size - iconPainter.height) / 2,
      );
      iconPainter.paint(canvas, iconOffset);

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (e, st) {
      debugPrint('❌ Trip-planner marker icon failed: $e\n$st');
      return null;
    }
  }

  LatLngBounds _boundsFor(List<LatLngNamedModel> points) {
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

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String formatPkr(int amount) => 'PKR $amount';

  void openChargingStationDetails(
    BuildContext context, {
    required HubcoLocationEntity station,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChargingStationDetailPage(station: station),
      ),
    );
  }

  void openPreBook(
    BuildContext context, {
    required HubcoLocationEntity station,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookSlotPage(
          stationName: station.name,
          stationAddress: station.address,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    state.mapController?.dispose();
    _startLocationController
      ..removeListener(_onLocationChanged)
      ..dispose();
    _endLocationController
      ..removeListener(_onLocationChanged)
      ..dispose();
    return super.close();
  }
}

