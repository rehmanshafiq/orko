import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class TripPlannerRouteSelected extends TripPlannerEvent {
  const TripPlannerRouteSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
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

