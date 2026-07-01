import 'package:equatable/equatable.dart';

/// Available filter options from `GET api/v1/charging-station/filter-options/`
/// — used to populate the map filters sheet.
class StationFilterOptionsEntity extends Equatable {
  const StationFilterOptionsEntity({
    this.amenities = const [],
    this.powerOutputOptions = const [],
    this.priceMin,
    this.priceMax,
    this.cities = const [],
  });

  final List<AmenityOptionEntity> amenities;

  /// Selectable power-output values (kW) from the API's `power_output` list.
  final List<double> powerOutputOptions;

  /// Price-range slider bounds (per kWh) from the API's `price_range: [min, max]`.
  final double? priceMin;
  final double? priceMax;

  /// Selectable city names from the API's `cities` list, filtered down to
  /// the currently supported KLI cities (Karachi, Lahore, Islamabad).
  final List<String> cities;

  @override
  List<Object?> get props => [
        amenities,
        powerOutputOptions,
        priceMin,
        priceMax,
        cities,
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
