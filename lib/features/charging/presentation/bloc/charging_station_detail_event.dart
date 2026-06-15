import 'package:equatable/equatable.dart';

abstract class ChargingStationDetailEvent extends Equatable {
  const ChargingStationDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers loading the station detail from the API.
class ChargingStationDetailRequested extends ChargingStationDetailEvent {
  const ChargingStationDetailRequested({
    required this.stationId,
    required this.latitude,
    required this.longitude,
  });

  final String stationId;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [stationId, latitude, longitude];
}

class ChargingStationDetailFavoriteToggled extends ChargingStationDetailEvent {
  const ChargingStationDetailFavoriteToggled();
}

class ChargingStationDetailPortSelected extends ChargingStationDetailEvent {
  const ChargingStationDetailPortSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}
