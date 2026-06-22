import 'package:orko_hubco/features/vehicle/domain/entities/created_vehicle_entity.dart';

/// Maps the `body` object from `POST api/v1/vehicle/add-vehicle/`.
class CreatedVehicleModel extends CreatedVehicleEntity {
  const CreatedVehicleModel({
    required super.id,
    required super.mdMake,
    required super.mdModel,
  });

  factory CreatedVehicleModel.fromJson(Map<String, dynamic> json) {
    return CreatedVehicleModel(
      id: _asInt(json['id']),
      mdMake: _asInt(json['md_make']),
      mdModel: _asInt(json['md_model']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
