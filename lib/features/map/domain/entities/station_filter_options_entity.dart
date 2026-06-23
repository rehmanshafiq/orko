import 'package:equatable/equatable.dart';

/// Available filter options from `GET api/v1/charging-station/filter-options/`
/// — used to populate the map filters sheet.
class StationFilterOptionsEntity extends Equatable {
  const StationFilterOptionsEntity({
    this.connectorTypes = const [],
    this.amenities = const [],
    this.powerOutputMin,
    this.powerOutputMax,
    this.priceMin,
    this.priceMax,
  });

  final List<String> connectorTypes;
  final List<AmenityOptionEntity> amenities;

  /// Power-output slider bounds (kW) from the API's `power_output: [min, max]`.
  /// Null when the API omits them — the UI falls back to its defaults.
  final double? powerOutputMin;
  final double? powerOutputMax;

  /// Price-range slider bounds (per kWh) from the API's `price_range: [min, max]`.
  final double? priceMin;
  final double? priceMax;

  @override
  List<Object?> get props => [
        connectorTypes,
        amenities,
        powerOutputMin,
        powerOutputMax,
        priceMin,
        priceMax,
      ];
}

/// A selectable amenity (`{id, name}`) from the filter options.
class AmenityOptionEntity extends Equatable {
  const AmenityOptionEntity({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
