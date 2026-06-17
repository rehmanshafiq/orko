import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

class HubcoLocationModel extends HubcoLocationEntity {
  const HubcoLocationModel({
    required super.id,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.status,
    super.distance,
    super.iconUrl,
    super.numberOfConnectors,
    super.availableConnectors,
    super.prices,
  });

  /// Parses the bundled-asset / flat shape (`hubco_locations.json`).
  factory HubcoLocationModel.fromJson(Map<String, dynamic> json) {
    return HubcoLocationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: json['status'] == true,
    );
  }

  /// Parses a single station from the `charging-station/nearest` API response,
  /// where coordinates are nested under `location` (`lat`/`long`).
  factory HubcoLocationModel.fromNearestJson(Map<String, dynamic> json) {
    final location = json['location'];
    final locationMap =
        location is Map ? Map<String, dynamic>.from(location) : const {};

    return HubcoLocationModel(
      id: int.tryParse('${json['location_id'] ?? ''}') ?? 0,
      name: (json['name'] ?? '').toString(),
      address: (json['address_guide'] ?? '').toString(),
      latitude: (locationMap['lat'] as num?)?.toDouble() ?? 0,
      longitude: (locationMap['long'] as num?)?.toDouble() ?? 0,
      status: json['status'] == true,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      iconUrl: (json['icon_with_background'] ?? '').toString(),
      numberOfConnectors: _asInt(json['number_of_connectors']),
      availableConnectors: _asInt(json['available_connectors']),
      prices: _asList(json['prices']).map(_priceFromJson).toList(growable: false),
    );
  }

  static StationPriceEntity _priceFromJson(Map<String, dynamic> json) {
    return StationPriceEntity(
      pricingMode: (json['pricing_mode'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
