import 'package:orko_hubco/features/map/domain/entities/station_filter_options_entity.dart';

/// Maps the `body` object from `GET api/v1/charging-station/filter-options/`.
/// Parsed defensively so missing/malformed keys can never throw.
class StationFilterOptionsModel extends StationFilterOptionsEntity {
  const StationFilterOptionsModel({
    super.amenities,
    super.powerOutputOptions,
    super.priceMin,
    super.priceMax,
    super.cities,
  });

  /// Cities currently supported by the app's Location filter — the API may
  /// return other cities, but only these are selectable for now.
  static const _supportedCities = {'karachi', 'lahore', 'islamabad'};

  factory StationFilterOptionsModel.fromJson(Map<String, dynamic> json) {
    final rawAmenities = json['amenities'];
    final rawPowerOutput = json['power_output'];
    final rawCities = json['cities'];
    final priceRange = _asRange(json['price_range']);

    final amenities = rawAmenities is List
        ? rawAmenities
            .whereType<Map>()
            .map((e) => _amenityFromJson(Map<String, dynamic>.from(e)))
            .where((a) => a.name.isNotEmpty)
            .toList(growable: false)
        : const <AmenityOptionEntity>[];

    final powerOutputOptions = rawPowerOutput is List
        ? rawPowerOutput
            .map(_asDouble)
            .whereType<double>()
            .toList(growable: false)
        : const <double>[];

    final cities = rawCities is List
        ? rawCities
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => _supportedCities.contains(e.toLowerCase()))
            .toList(growable: false)
        : const <String>[];

    return StationFilterOptionsModel(
      amenities: amenities,
      powerOutputOptions: powerOutputOptions,
      priceMin: priceRange?.$1,
      priceMax: priceRange?.$2,
      cities: cities,
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
