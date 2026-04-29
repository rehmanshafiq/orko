import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapLoaded extends MapState {
  final List<HubcoLocationEntity> locations;

  const MapLoaded(this.locations);

  @override
  List<Object?> get props => [locations];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}
