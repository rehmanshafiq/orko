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
    this.vehicleTech,
    this.totalCharges = 0,
    this.totalEnergyCharged = 0,
  });

  /// `csms_vehicle_id` — pass this into the compatibility endpoint.
  final int id;
  final String makeName;
  final String modelName;
  final String year;
  final String connectorType;

  /// `vehicle_tech` — powertrain type, e.g. `BEV`, `PHEV`, `HEV`. Null/empty
  /// when the API omits it. Use [isPhev] rather than comparing raw strings.
  final String? vehicleTech;

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

  /// True when this is a Plug-in Hybrid (PHEV). Case/whitespace-insensitive so a
  /// value like `" phev "` still matches.
  bool get isPhev => (vehicleTech ?? '').trim().toUpperCase() == 'PHEV';

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
        vehicleTech,
        totalCharges,
        totalEnergyCharged,
      ];
}
