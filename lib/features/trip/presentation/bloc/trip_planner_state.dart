import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';

class TripPlannerState extends Equatable {
  const TripPlannerState({
    required this.currentBatteryPercent,
    required this.targetArrivalBatteryPercent,
    required this.tripPlanned,
    required this.selectedRouteIndex,
    required this.expandedChargingStopIndex,
    required this.routePlans,
    required this.mapController,
    required this.mapControllerCompleter,
    required this.iconsLoaded,
    required this.stopIcon,
    required this.startIcon,
    required this.endIcon,
  });

  factory TripPlannerState.initial() {
    return TripPlannerState(
      currentBatteryPercent: 60,
      targetArrivalBatteryPercent: 20,
      tripPlanned: false,
      selectedRouteIndex: 0,
      expandedChargingStopIndex: null,
      routePlans: const [null, null],
      mapController: null,
      mapControllerCompleter: Completer<GoogleMapController>(),
      iconsLoaded: false,
      stopIcon: null,
      startIcon: null,
      endIcon: null,
    );
  }

  final double currentBatteryPercent;
  final double targetArrivalBatteryPercent;
  final bool tripPlanned;
  final int selectedRouteIndex;
  final int? expandedChargingStopIndex;
  final List<TripPlanModel?> routePlans;
  final GoogleMapController? mapController;
  final Completer<GoogleMapController> mapControllerCompleter;
  final bool iconsLoaded;
  final BitmapDescriptor? stopIcon;
  final BitmapDescriptor? startIcon;
  final BitmapDescriptor? endIcon;

  TripPlanModel? get currentPlan => routePlans[selectedRouteIndex];

  TripPlannerState copyWith({
    double? currentBatteryPercent,
    double? targetArrivalBatteryPercent,
    bool? tripPlanned,
    int? selectedRouteIndex,
    int? expandedChargingStopIndex,
    bool resetExpandedChargingStopIndex = false,
    List<TripPlanModel?>? routePlans,
    GoogleMapController? mapController,
    Completer<GoogleMapController>? mapControllerCompleter,
    bool? iconsLoaded,
    BitmapDescriptor? stopIcon,
    BitmapDescriptor? startIcon,
    BitmapDescriptor? endIcon,
  }) {
    return TripPlannerState(
      currentBatteryPercent: currentBatteryPercent ?? this.currentBatteryPercent,
      targetArrivalBatteryPercent:
          targetArrivalBatteryPercent ?? this.targetArrivalBatteryPercent,
      tripPlanned: tripPlanned ?? this.tripPlanned,
      selectedRouteIndex: selectedRouteIndex ?? this.selectedRouteIndex,
      expandedChargingStopIndex: resetExpandedChargingStopIndex
          ? null
          : (expandedChargingStopIndex ?? this.expandedChargingStopIndex),
      routePlans: routePlans ?? this.routePlans,
      mapController: mapController ?? this.mapController,
      mapControllerCompleter: mapControllerCompleter ?? this.mapControllerCompleter,
      iconsLoaded: iconsLoaded ?? this.iconsLoaded,
      stopIcon: stopIcon ?? this.stopIcon,
      startIcon: startIcon ?? this.startIcon,
      endIcon: endIcon ?? this.endIcon,
    );
  }

  @override
  List<Object?> get props => [
        currentBatteryPercent,
        targetArrivalBatteryPercent,
        tripPlanned,
        selectedRouteIndex,
        expandedChargingStopIndex,
        routePlans,
        mapController,
        mapControllerCompleter,
        iconsLoaded,
        stopIcon,
        startIcon,
        endIcon,
      ];
}

