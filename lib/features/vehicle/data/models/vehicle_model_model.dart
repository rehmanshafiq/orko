import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_model_entity.dart';

/// Maps a `body.results` item from `GET api/v1/vehicle/models/`.
class VehicleModelModel extends VehicleModelEntity {
  const VehicleModelModel({
    required super.id,
    required super.name,
    super.connectorType,
  });

  factory VehicleModelModel.fromJson(Map<String, dynamic> json) {
    final connector = json['connector_type'];
    final connectorStr = connector?.toString().trim();
    return VehicleModelModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      connectorType:
          (connectorStr == null || connectorStr.isEmpty) ? null : connectorStr,
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
