import 'package:orko_hubco/features/search/domain/entities/station_result_entity.dart';

/// Maps the search and popular station responses into [StationResultEntity].
/// Parsed defensively so a missing or malformed key can never throw.
class StationResultModel extends StationResultEntity {
  const StationResultModel({
    required super.id,
    required super.name,
    super.subtitle,
    super.distanceKm,
    super.numberOfConnectors,
    super.availableConnectors,
    super.available,
    super.powerTypes,
    super.powerRatings,
    super.connectorTypes,
    super.averageRating,
    super.latitude,
    super.longitude,
  });

  /// Parses an item from the `body.stations` array of
  /// `POST api/v1/charging-station/search/`.
  factory StationResultModel.fromSearchJson(Map<String, dynamic> json) {
    final location = json['location'];
    final locationMap =
        location is Map ? Map<String, dynamic>.from(location) : const {};

    return StationResultModel(
      id: _asInt(json['location_id']),
      name: (json['name'] ?? '').toString().trim(),
      subtitle: (json['parent_company'] ?? '').toString().trim(),
      distanceKm: _asDouble(json['distance']),
      numberOfConnectors: _asInt(json['number_of_connectors']),
      availableConnectors: _asInt(json['available_connectors']),
      available: json['available'] == true,
      powerTypes: _asStringList(json['type']),
      powerRatings: _asStringList(json['power']),
      connectorTypes: _asStringList(json['connector_types']),
      latitude: _asDouble(locationMap['lat']),
      longitude: _asDouble(locationMap['long']),
    );
  }

  /// Parses an item from the `body` array of
  /// `GET api/v1/charging-station/popular/`.
  factory StationResultModel.fromPopularJson(Map<String, dynamic> json) {
    return StationResultModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      subtitle: (json['city'] ?? '').toString().trim(),
      distanceKm: _asDouble(json['distance']),
      numberOfConnectors: _asInt(json['number_of_connectors']),
      availableConnectors: _asInt(json['available_connectors']),
      available: json['available'] == true,
      powerTypes: _asStringList(json['type']),
      powerRatings: _asStringList(json['power']),
      connectorTypes: _asStringList(json['connector_types']),
      averageRating: json['average_rating'] == null
          ? null
          : _asDouble(json['average_rating']),
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}') ?? 0;
  }
}
