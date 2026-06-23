import 'package:orko_hubco/features/map/domain/entities/station_filter_options_entity.dart';

/// Maps the `body` object from `GET api/v1/charging-station/filter-options/`.
/// Parsed defensively so missing/malformed keys can never throw.
class StationFilterOptionsModel extends StationFilterOptionsEntity {
  const StationFilterOptionsModel({
    super.connectorTypes,
    super.amenities,
    super.powerOutputMin,
    super.powerOutputMax,
    super.priceMin,
    super.priceMax,
  });

  factory StationFilterOptionsModel.fromJson(Map<String, dynamic> json) {
    final rawConnectors = json['connector_types'];
    final rawAmenities = json['amenities'];
    final powerRange = _asRange(json['power_output']);
    final priceRange = _asRange(json['price_range']);

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
      powerOutputMin: powerRange?.$1,
      powerOutputMax: powerRange?.$2,
      priceMin: priceRange?.$1,
      priceMax: priceRange?.$2,
    );
  }

  /// Parses a `[min, max]` numeric pair, returning it low→high. Null when the
  /// value isn't a usable 2-element numeric list.
  static (double, double)? _asRange(dynamic value) {
    if (value is List && value.length >= 2) {
      final a = _asDouble(value[0]);
      final b = _asDouble(value[1]);
      if (a != null && b != null) {
        return a <= b ? (a, b) : (b, a);
      }
    }
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
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
