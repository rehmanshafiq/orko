import 'package:equatable/equatable.dart';

abstract class ChargingStationDetailEvent extends Equatable {
  const ChargingStationDetailEvent();

  @override
  List<Object?> get props => [];
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
