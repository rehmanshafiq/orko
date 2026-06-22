import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_make_entity.dart';

/// Maps a `body.results` item from `GET api/v1/vehicle/makes/`.
class VehicleMakeModel extends VehicleMakeEntity {
  const VehicleMakeModel({required super.id, required super.name});

  factory VehicleMakeModel.fromJson(Map<String, dynamic> json) {
    return VehicleMakeModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
