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

  /// True when [locations] came from the bundled offline asset (the remote
  /// nearest API failed), false when they came from the API. Surfaced for the
  /// `map_view` analytics event.
  final bool usedAssetFallback;

  const MapLoaded(this.locations, {this.usedAssetFallback = false});

  @override
  List<Object?> get props => [locations, usedAssetFallback];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}
