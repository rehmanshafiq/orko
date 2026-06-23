import 'package:equatable/equatable.dart';

/// A single charging station as returned by the search
/// (`POST api/v1/charging-station/search/`) and popular
/// (`GET api/v1/charging-station/popular/`) endpoints.
///
/// The two responses overlap but aren't identical — search carries
/// coordinates and a parent company, popular carries a city and an average
/// rating. Both map into this one shape so the UI renders them uniformly;
/// fields a given endpoint doesn't provide fall back to sensible defaults.
class StationResultEntity extends Equatable {
  const StationResultEntity({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.distanceKm = 0,
    this.numberOfConnectors = 0,
    this.availableConnectors = 0,
    this.available = false,
    this.powerTypes = const [],
    this.connectorTypes = const [],
    this.averageRating,
    this.latitude = 0,
    this.longitude = 0,
  });

  /// `location_id` (search) or `id` (popular). 0 when unknown.
  final int id;
  final String name;

  /// Secondary line: parent company (search) or city (popular).
  final String subtitle;

  /// Distance from the requesting device, in kilometers (0 when unknown).
  final double distanceKm;

  final int numberOfConnectors;
  final int availableConnectors;

  /// Whether the station currently has an available connector.
  final bool available;

  /// Power kinds from the `type` array, e.g. `['DC']`, `['AC', 'AC/DC']`.
  final List<String> powerTypes;

  /// Connector kinds from `connector_types`, e.g. `['CCS2', 'CHAdeMO']`
  /// (popular only — empty for search results).
  final List<String> connectorTypes;

  /// Average rating (popular only — null for search results).
  final double? averageRating;

  final double latitude;
  final double longitude;

  /// Chips shown on the station card: power types first, then connector types,
  /// de-duplicated and trimmed.
  List<String> get tags {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in [...powerTypes, ...connectorTypes]) {
      final value = tag.trim();
      if (value.isEmpty || !seen.add(value)) continue;
      result.add(value);
    }
    return result;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        subtitle,
        distanceKm,
        numberOfConnectors,
        availableConnectors,
        available,
        powerTypes,
        connectorTypes,
        averageRating,
        latitude,
        longitude,
      ];
}
