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
    );
  }
}
