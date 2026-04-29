import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

class HubcoLocationModel extends HubcoLocationEntity {
  const HubcoLocationModel({
    required super.id,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.status,
  });

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
}
