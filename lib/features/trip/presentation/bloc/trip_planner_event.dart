import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';

abstract class TripPlannerEvent extends Equatable {
  const TripPlannerEvent();

  @override
  List<Object?> get props => [];
}

class TripPlannerLocationChanged extends TripPlannerEvent {
  const TripPlannerLocationChanged();
}

class TripPlannerPlanTripPressed extends TripPlannerEvent {
  const TripPlannerPlanTripPressed();
}

/// Resolves origin/destination coordinates and calls the real `plan-trip` API.
class TripPlannerPlanTripRequested extends TripPlannerEvent {
  const TripPlannerPlanTripRequested();
}

/// Persists the most recently planned trip via the `save-trip` API.
class TripPlannerSaveTripRequested extends TripPlannerEvent {
  const TripPlannerSaveTripRequested();
}

/// Clears the form + planned trip back to the default state (keeps loaded
/// marker icons so a re-plan doesn't reload them).
class TripPlannerResetRequested extends TripPlannerEvent {
  const TripPlannerResetRequested();
}

class TripPlannerRouteSelected extends TripPlannerEvent {
  const TripPlannerRouteSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class TripPlannerVehicleSelected extends TripPlannerEvent {
  const TripPlannerVehicleSelected(this.vehicle);

  final UserVehicleEntity? vehicle;

  @override
  List<Object?> get props => [vehicle];
}

class TripPlannerBatteryChanged extends TripPlannerEvent {
  const TripPlannerBatteryChanged(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}

class TripPlannerArrivalBatteryChanged extends TripPlannerEvent {
  const TripPlannerArrivalBatteryChanged(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}

class TripPlannerChargingStopExpanded extends TripPlannerEvent {
  const TripPlannerChargingStopExpanded(this.stopIndex);

  final int stopIndex;

  @override
  List<Object?> get props => [stopIndex];
}

class TripPlannerLoadMarkerIcons extends TripPlannerEvent {
  const TripPlannerLoadMarkerIcons(this.devicePixelRatio);

  final double devicePixelRatio;

  @override
  List<Object?> get props => [devicePixelRatio];
}

class TripPlannerMapCreated extends TripPlannerEvent {
  const TripPlannerMapCreated(this.controller);

  final GoogleMapController controller;

  @override
  List<Object?> get props => [controller];
}

class TripPlannerFitMapRoute extends TripPlannerEvent {
  const TripPlannerFitMapRoute();
}

