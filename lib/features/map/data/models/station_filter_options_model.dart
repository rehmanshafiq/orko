import 'package:orko_hubco/features/map/domain/entities/station_filter_options_entity.dart';

/// Maps the `body` object from `GET api/v1/charging-station/filter-options/`.
/// Parsed defensively so missing/malformed keys can never throw.
class StationFilterOptionsModel extends StationFilterOptionsEntity {
  const StationFilterOptionsModel({
    super.connectorTypes,
    super.amenities,
  });

  factory StationFilterOptionsModel.fromJson(Map<String, dynamic> json) {
    final rawConnectors = json['connector_types'];
    final rawAmenities = json['amenities'];

    final connectorTypes = rawConnectors is List
        ? rawConnectors
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final amenities = rawAmenities is List
        ? rawAmenities
            .whereType<Map>()
            .map((e) => _amenityFromJson(Map<String, dynamic>.from(e)))
            .where((a) => a.name.isNotEmpty)
            .toList(growable: false)
        : const <AmenityOptionEntity>[];

    return StationFilterOptionsModel(
      connectorTypes: connectorTypes,
      amenities: amenities,
    );
  }

  static AmenityOptionEntity _amenityFromJson(Map<String, dynamic> json) {
    return AmenityOptionEntity(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
