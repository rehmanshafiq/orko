import 'package:equatable/equatable.dart';

/// The set of station filters the user has applied. Threaded into the `nearest`
/// API as query params (`connector_type`, `amenity_id`, `min_price`,
/// `max_price`, `power_output`). [availableNow] has no API param and is applied
/// client-side (stations with at least one available connector).
class StationFilters extends Equatable {
  const StationFilters({
    this.connectorTypes = const [],
    this.amenityIds = const [],
    this.minPrice,
    this.maxPrice,
    this.powerOutput,
    this.radius,
    this.availableNow = false,
  });

  final List<String> connectorTypes;

  /// Selected amenity ids. Sent as REPEATED query params
  /// (`amenity_id=1&amenity_id=3`), not comma-joined — the backend's filter
  /// rejects a `1,3` string with a 400.
  final List<int> amenityIds;
  final double? minPrice;
  final double? maxPrice;
  final double? powerOutput;
  final double? radius;
  final bool availableNow;

  /// True when no server-side or client-side filter is active.
  bool get isEmpty =>
      connectorTypes.isEmpty &&
      amenityIds.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      powerOutput == null &&
      radius == null &&
      !availableNow;

  @override
  List<Object?> get props => [
        connectorTypes,
        amenityIds,
        minPrice,
        maxPrice,
        powerOutput,
        radius,
        availableNow,
      ];
}
