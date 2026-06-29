import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';

/// Maps a `body` array item from `GET api/v1/vehicle/user-vehicle/`.
/// Parsed defensively so a null/missing field can never throw.
class UserVehicleModel extends UserVehicleEntity {
  const UserVehicleModel({
    required super.id,
    required super.makeName,
    required super.modelName,
    required super.year,
    required super.connectorType,
    super.registrationNo,
    super.modelImage,
    super.batteryCapacity,
    super.efficiency,
    super.range,
    super.totalCharges,
    super.totalEnergyCharged,
  });

  factory UserVehicleModel.fromJson(Map<String, dynamic> json) {
    final rawModelImage = json['model_image']?.toString();
    final rawRegistration = json['registration_no']?.toString();
    return UserVehicleModel(
      id: _asInt(json['id']),
      makeName: (json['make_name'] ?? '').toString(),
      modelName: (json['model_name'] ?? '').toString(),
      year: (json['year'] ?? '').toString(),
      connectorType: (json['connector_type'] ?? '').toString(),
      registrationNo:
          (rawRegistration == null || rawRegistration.trim().isEmpty)
              ? null
              : rawRegistration.trim(),
      modelImage: (rawModelImage == null || rawModelImage.isEmpty)
          ? null
          : rawModelImage,
      batteryCapacity: _asDoubleOrNull(json['battery_capacity']),
      efficiency: _asDoubleOrNull(json['efficiency']),
      range: _asDoubleOrNull(json['range']),
      totalCharges: _asInt(json['total_charges']),
      totalEnergyCharged: _asDoubleOrNull(json['total_energy_charged']) ?? 0,
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
