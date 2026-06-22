import 'package:equatable/equatable.dart';

/// Available filter options from `GET api/v1/charging-station/filter-options/`
/// — used to populate the map filters sheet.
class StationFilterOptionsEntity extends Equatable {
  const StationFilterOptionsEntity({
    this.connectorTypes = const [],
    this.amenities = const [],
  });

  final List<String> connectorTypes;
  final List<AmenityOptionEntity> amenities;

  @override
  List<Object?> get props => [connectorTypes, amenities];
}

/// A selectable amenity (`{id, name}`) from the filter options.
class AmenityOptionEntity extends Equatable {
  const AmenityOptionEntity({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
