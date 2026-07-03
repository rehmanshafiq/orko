import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_plan_entity.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';

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
    this.selectedVehicle,
    this.planLoading = false,
    this.planError,
    this.feasible,
    this.apiPlan,
    this.lastPlanParams,
    this.saving = false,
    this.saveError,
    this.saveSuccess = false,
    this.editTripId,
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
      selectedVehicle: null,
      planLoading: false,
      planError: null,
      feasible: null,
      apiPlan: null,
      lastPlanParams: null,
      saving: false,
      saveError: null,
      saveSuccess: false,
      editTripId: null,
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

  /// The vehicle picked in the dropdown; drives the EV Details card.
  final UserVehicleEntity? selectedVehicle;

  /// True while a `plan-trip` request is in flight.
  final bool planLoading;

  /// User-facing error for the last plan attempt (null when none).
  final String? planError;

  /// `false` when the API reports the trip can't be completed with available
  /// chargers (a warning state, not an error). Null until a plan runs.
  final bool? feasible;

  /// The raw API plan; non-null after a successful plan-trip call.
  final TripPlanEntity? apiPlan;

  /// The params behind the current [apiPlan], reused by save-trip.
  final TripPlanParams? lastPlanParams;

  /// True while a `save-trip` request is in flight.
  final bool saving;

  /// User-facing error for the last save attempt (null when none).
  final String? saveError;

  /// True for one emission after a successful save.
  final bool saveSuccess;

  /// Non-null when the planner was opened to edit an existing saved trip; holds
  /// that trip's id. Drives the "Edit Trip" button and the edit API call.
  final int? editTripId;

  /// Convenience: the planner is in edit mode.
  bool get isEditMode => editTripId != null;

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
    UserVehicleEntity? selectedVehicle,
    bool clearSelectedVehicle = false,
    bool? planLoading,
    String? planError,
    bool clearPlanError = false,
    bool? feasible,
    bool clearFeasible = false,
    TripPlanEntity? apiPlan,
    bool clearApiPlan = false,
    TripPlanParams? lastPlanParams,
    bool clearLastPlanParams = false,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
    bool? saveSuccess,
    int? editTripId,
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
      selectedVehicle:
          clearSelectedVehicle ? null : (selectedVehicle ?? this.selectedVehicle),
      planLoading: planLoading ?? this.planLoading,
      planError: clearPlanError ? null : (planError ?? this.planError),
      feasible: clearFeasible ? null : (feasible ?? this.feasible),
      apiPlan: clearApiPlan ? null : (apiPlan ?? this.apiPlan),
      lastPlanParams:
          clearLastPlanParams ? null : (lastPlanParams ?? this.lastPlanParams),
      saving: saving ?? this.saving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      saveSuccess: saveSuccess ?? this.saveSuccess,
      editTripId: editTripId ?? this.editTripId,
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
        selectedVehicle,
        planLoading,
        planError,
        feasible,
        apiPlan,
        lastPlanParams,
        saving,
        saveError,
        saveSuccess,
        editTripId,
      ];
}

