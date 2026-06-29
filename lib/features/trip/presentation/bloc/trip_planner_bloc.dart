import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/charging_stations.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/booking/presentation/pages/book_slot_page.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/charging/presentation/page/charging_station_detail_page.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_plan_entity.dart';
import 'package:orko_hubco/features/trip/domain/usecases/plan_trip_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/save_trip_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_event.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_state.dart';
import 'package:orko_hubco/features/trip/presentation/models/latlng_named_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/route_strategy_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/stop_charge_info_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';

class TripPlannerBloc extends Bloc<TripPlannerEvent, TripPlannerState> {
  TripPlannerBloc({
    PlanTripUseCase? planTrip,
    SaveTripUseCase? saveTrip,
  })  : _planTrip = planTrip ?? sl<PlanTripUseCase>(),
        _saveTrip = saveTrip ?? sl<SaveTripUseCase>(),
        super(TripPlannerState.initial()) {
    _startLocationController.addListener(_onLocationChanged);
    _endLocationController.addListener(_onLocationChanged);

    on<TripPlannerLocationChanged>(_handleLocationChanged);
    on<TripPlannerPlanTripPressed>(_handlePlanTripPressed);
    on<TripPlannerPlanTripRequested>(_handlePlanTripRequested);
    on<TripPlannerSaveTripRequested>(_handleSaveTripRequested);
    on<TripPlannerRouteSelected>(_handleRouteSelected);
    on<TripPlannerVehicleSelected>(_handleVehicleSelected);
    on<TripPlannerBatteryChanged>(_handleBatteryChanged);
    on<TripPlannerArrivalBatteryChanged>(_handleArrivalBatteryChanged);
    on<TripPlannerChargingStopExpanded>(_handleChargingStopExpanded);
    on<TripPlannerLoadMarkerIcons>(_handleLoadMarkerIcons);
    on<TripPlannerMapCreated>(_handleMapCreated);
    on<TripPlannerFitMapRoute>(_handleFitMapRoute);
  }

  final PlanTripUseCase _planTrip;
  final SaveTripUseCase _saveTrip;

  /// 100% state of charge = 380 km usable range.
  static const double kmPerPercentCharge = 3.8;

  /// Multiplier applied to great-circle distance to approximate road distance.
  static const double roadFactor = 1.15;

  /// Logical (dp) marker side for start/end location pins on the mini-map.
  static const double stationMarkerSize = 12;

  /// Charger stop pins — same logical size as home map markers.
  static const double _chargerStopMarkerSize = 44;

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

  final TextEditingController _startLocationController = TextEditingController();
  final TextEditingController _endLocationController = TextEditingController();

  TextEditingController get startLocationController => _startLocationController;
  TextEditingController get endLocationController => _endLocationController;

  /// Exact coordinates chosen via Google Places, kept so trip planning uses the
  /// picked place instead of the limited [HubcoChargingStations.resolveCity]
  /// lookup. Cleared implicitly when the field text no longer matches.
  ({double lat, double lng, String name})? _startPlace;
  ({double lat, double lng, String name})? _endPlace;

  /// Records a Places selection for the start field and reflects it in the
  /// text controller.
  void selectStartPlace({
    required String name,
    required double lat,
    required double lng,
  }) {
    _startPlace = (lat: lat, lng: lng, name: name);
    _startLocationController.text = name;
  }

  /// Records a Places selection for the destination field.
  void selectEndPlace({
    required String name,
    required double lat,
    required double lng,
  }) {
    _endPlace = (lat: lat, lng: lng, name: name);
    _endLocationController.text = name;
  }

  void _onLocationChanged() {
    add(const TripPlannerLocationChanged());
  }

  void _handleLocationChanged(
    TripPlannerLocationChanged event,
    Emitter<TripPlannerState> emit,
  ) {
    if (!state.tripPlanned) return;
    // Live API results stand until the user re-taps Plan Trip; never let the
    // mock recompute clobber them on keystroke.
    if (state.apiPlan != null) return;
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

  Future<void> _handlePlanTripRequested(
    TripPlannerPlanTripRequested event,
    Emitter<TripPlannerState> emit,
  ) async {
    emit(state.copyWith(
      planLoading: true,
      clearPlanError: true,
      clearSaveError: true,
      saveSuccess: false,
    ));

    // 1. Resolve origin/destination coordinates.
    final origin = await _resolvePoint(
      text: _startLocationController.text,
      isOrigin: true,
      selected: _startPlace,
    );
    if (origin == null) {
      emit(state.copyWith(
        planLoading: false,
        planError:
            'Couldn\'t find your start location. Try a known city, or enable location for "current location".',
      ));
      return;
    }
    final destination = await _resolvePoint(
      text: _endLocationController.text,
      isOrigin: false,
      selected: _endPlace,
    );
    if (destination == null) {
      emit(state.copyWith(
        planLoading: false,
        planError:
            'Couldn\'t find your destination. Try entering a known city name.',
      ));
      return;
    }

    // 2. Block a selected-but-incomplete vehicle (mirrors the picker rule).
    final vehicle = state.selectedVehicle;
    if (vehicle != null &&
        (vehicle.range == null ||
            vehicle.range == 0 ||
            vehicle.batteryCapacity == null)) {
      emit(state.copyWith(
        planLoading: false,
        planError: 'Vehicle battery/range data is incomplete.',
      ));
      return;
    }

    final params = TripPlanParams(
      originLatitude: origin.lat,
      originLongitude: origin.lng,
      destinationLatitude: destination.lat,
      destinationLongitude: destination.lng,
      originAddress: origin.name,
      destinationAddress: destination.name,
      customerVehicleId: vehicle?.id,
      startSoc: state.currentBatteryPercent.toInt(),
      targetSoc: 100,
      reserveSoc: 10,
      corridorKm: 20,
    );

    // 3. Call the API.
    final result = await _planTrip(params);
    result.fold(
      (failure) => emit(state.copyWith(
        planLoading: false,
        planError: failure.message,
      )),
      (plan) {
        final startPoint = GeoPoint(
          name: origin.name,
          latitude: origin.lat,
          longitude: origin.lng,
        );
        final endPoint = GeoPoint(
          name: destination.name,
          latitude: destination.lat,
          longitude: destination.lng,
        );
        final mapped = _mapApiPlanToModel(plan, startPoint, endPoint);
        emit(state.copyWith(
          planLoading: false,
          tripPlanned: true,
          apiPlan: plan,
          feasible: plan.feasible,
          lastPlanParams: params,
          clearPlanError: true,
          routePlans: <TripPlanModel?>[mapped],
          selectedRouteIndex: 0,
          resetExpandedChargingStopIndex: true,
        ));
        add(const TripPlannerFitMapRoute());
      },
    );
  }

  Future<void> _handleSaveTripRequested(
    TripPlannerSaveTripRequested event,
    Emitter<TripPlannerState> emit,
  ) async {
    final params = state.lastPlanParams;
    if (params == null) {
      emit(state.copyWith(saveError: 'Plan a trip before saving.'));
      return;
    }
    emit(state.copyWith(saving: true, clearSaveError: true, saveSuccess: false));
    final result = await _saveTrip(params);
    result.fold(
      (failure) => emit(state.copyWith(saving: false, saveError: failure.message)),
      (_) => emit(state.copyWith(saving: false, saveSuccess: true)),
    );
  }

  /// Resolves a typed location (or device GPS for an empty/"current" origin)
  /// into coordinates. Returns null when nothing resolves.
  Future<({double lat, double lng, String name})?> _resolvePoint({
    required String text,
    required bool isOrigin,
    ({double lat, double lng, String name})? selected,
  }) async {
    final trimmed = text.trim();

    // Prefer the exact Google Places selection while it matches the field text.
    if (selected != null && selected.name == trimmed) {
      return selected;
    }

    final wantsGps = isOrigin &&
        (trimmed.isEmpty || trimmed.toLowerCase() == 'current location');

    if (wantsGps) {
      final position = await _resolveCurrentPosition();
      if (position != null) {
        return (
          lat: position.latitude,
          lng: position.longitude,
          name: 'Current location',
        );
      }
      // Fall through to text resolution if GPS is unavailable.
    }

    final geo = HubcoChargingStations.resolveCity(trimmed);
    if (geo != null) {
      return (lat: geo.latitude, lng: geo.longitude, name: geo.name);
    }
    return null;
  }

  /// Device GPS with permission handling and a 10s cap (mirrors MapCubit).
  Future<Position?> _resolveCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[Trip] Failed to resolve current position: $e');
      return null;
    }
  }

  /// Adapts the API [TripPlanEntity] to the presentation [TripPlanModel] the
  /// map/stops/summary widgets already consume. `stops[i]` and `chargeInfo[i]`
  /// are built from the same source stop so their indices stay aligned.
  TripPlanModel _mapApiPlanToModel(
    TripPlanEntity plan,
    GeoPoint start,
    GeoPoint end,
  ) {
    final stations = <HubcoLocationEntity>[];
    final chargeInfo = <StopChargeInfoModel>[];
    for (final s in plan.stops) {
      stations.add(
        HubcoLocationEntity(
          id: s.locationId,
          name: s.locationName,
          address: s.locationAddress ?? '',
          latitude: s.latitude,
          longitude: s.longitude,
          status: true,
          connectorTypes: s.connectorType.isEmpty ? const [] : [s.connectorType],
        ),
      );
      chargeInfo.add(
        StopChargeInfoModel(
          arrivePct: s.arrivalSoc.round(),
          departPct: s.departureSoc.round(),
          minutes: s.chargingMinutes.round(),
          costPkr: s.cost.round(),
          amenities: s.amenities,
        ),
      );
    }

    final waypoints = <LatLngNamedModel>[
      LatLngNamedModel(start.name, start.latitude, start.longitude),
      ...plan.stops
          .map((s) => LatLngNamedModel(s.locationName, s.latitude, s.longitude)),
      LatLngNamedModel(end.name, end.latitude, end.longitude),
    ];

    final totalMinutes =
        (plan.totalDriveMinutes + plan.totalChargingMinutes).round();

    return TripPlanModel(
      strategy: strategies.first,
      start: start,
      end: end,
      stops: stations,
      waypoints: waypoints,
      chargeInfo: chargeInfo,
      distanceKm: plan.totalDistanceKm,
      duration: Duration(minutes: totalMinutes),
      costPkr: plan.totalCost.round(),
      co2SavedKg: (plan.totalDistanceKm * 0.12).round(),
    );
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

  void _handleVehicleSelected(
    TripPlannerVehicleSelected event,
    Emitter<TripPlannerState> emit,
  ) {
    emit(
      state.copyWith(
        selectedVehicle: event.vehicle,
        clearSelectedVehicle: event.vehicle == null,
      ),
    );
  }

  void _handleBatteryChanged(
    TripPlannerBatteryChanged event,
    Emitter<TripPlannerState> emit,
  ) {
    final nextState = state.copyWith(currentBatteryPercent: event.value);
    // With a live API plan, the slider only updates the EV card; recompute the
    // route by re-tapping Plan Trip. Without one, keep the mock recompute.
    final recompute = nextState.tripPlanned && nextState.apiPlan == null;
    emit(
      nextState.copyWith(
        routePlans: recompute ? _recomputeAllPlans(nextState) : null,
      ),
    );
  }

  void _handleArrivalBatteryChanged(
    TripPlannerArrivalBatteryChanged event,
    Emitter<TripPlannerState> emit,
  ) {
    final nextState = state.copyWith(targetArrivalBatteryPercent: event.value);
    final recompute = nextState.tripPlanned && nextState.apiPlan == null;
    emit(
      nextState.copyWith(
        routePlans: recompute ? _recomputeAllPlans(nextState) : null,
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

    final stop = await _loadChargerMapMarkerIcon(event.devicePixelRatio);
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

  /// Same green charger pin as the home map (`ic_charger_map`).
  Future<BitmapDescriptor?> _loadChargerMapMarkerIcon(double dpr) async {
    try {
      final targetWidth =
          (_chargerStopMarkerSize * dpr).round().clamp(1, 512);

      final data = await rootBundle.load(AppImages.icChargerMap);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final pngBytes = await _tintedPngBytes(
        image,
        AppColors.primaryDarkColor,
      );
      image.dispose();

      if (pngBytes == null) return null;

      return BitmapDescriptor.bytes(
        pngBytes,
        width: _chargerStopMarkerSize,
      );
    } catch (e, st) {
      debugPrint('❌ Trip-planner charger map marker failed: $e\n$st');
      return null;
    }
  }

  Future<Uint8List?> _tintedPngBytes(ui.Image source, Color tint) async {
    final rawData =
        await source.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rawData == null) return null;

    final pixels = rawData.buffer.asUint8List();
    for (var i = 0; i < pixels.length; i += 4) {
      final alpha = pixels[i + 3];
      if (alpha == 0) continue;

      final lum = (0.2126 * pixels[i] +
              0.7152 * pixels[i + 1] +
              0.0722 * pixels[i + 2]) /
          255;

      pixels[i] = (tint.red * lum).round().clamp(0, 255);
      pixels[i + 1] = (tint.green * lum).round().clamp(0, 255);
      pixels[i + 2] = (tint.blue * lum).round().clamp(0, 255);
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      source.width,
      source.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final tintedImage = await completer.future;
    final pngData = await tintedImage.toByteData(format: ui.ImageByteFormat.png);
    tintedImage.dispose();
    return pngData?.buffer.asUint8List();
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
          locationId: station.id,
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

