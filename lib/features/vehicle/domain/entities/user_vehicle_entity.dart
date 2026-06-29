import 'package:equatable/equatable.dart';

/// A vehicle belonging to the logged-in user, from
/// `GET api/v1/vehicle/user-vehicle/`. The [id] is the `csms_vehicle_id` used
/// by the charger-compatibility check.
class UserVehicleEntity extends Equatable {
  const UserVehicleEntity({
    required this.id,
    required this.makeName,
    required this.modelName,
    required this.year,
    required this.connectorType,
    this.registrationNo,
    this.modelImage,
    this.batteryCapacity,
    this.efficiency,
    this.range,
    this.totalCharges = 0,
    this.totalEnergyCharged = 0,
  });

  /// `csms_vehicle_id` — pass this into the compatibility endpoint.
  final int id;
  final String makeName;
  final String modelName;
  final String year;
  final String connectorType;

  /// `registration_no` — vehicle registration/plate number, when available.
  final String? registrationNo;

  /// `model_image` — URL of the vehicle model's image, when available.
  final String? modelImage;
  final double? batteryCapacity;
  final double? efficiency;
  final double? range;
  final int totalCharges;
  final double totalEnergyCharged;

  /// `BYD ATTO 3` — make + model, trimmed of empties.
  String get displayName {
    final parts = [makeName.trim(), modelName.trim()].where((p) => p.isNotEmpty);
    final joined = parts.join(' ');
    return joined.isEmpty ? 'Vehicle #$id' : joined;
  }

  @override
  List<Object?> get props => [
        id,
        makeName,
        modelName,
        year,
        connectorType,
        registrationNo,
        modelImage,
        batteryCapacity,
        efficiency,
        range,
        totalCharges,
        totalEnergyCharged,
      ];
}
