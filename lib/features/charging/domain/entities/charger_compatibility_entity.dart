import 'package:equatable/equatable.dart';

/// Result of `POST api/v1/charging-station/charger-compatibility/`.
class ChargerCompatibilityEntity extends Equatable {
  const ChargerCompatibilityEntity({
    required this.isCompatible,
    required this.compatibleConnectors,
    required this.incompatibleConnectors,
    this.vehicle,
  });

  final bool isCompatible;
  final CompatibilityVehicleEntity? vehicle;
  final List<CompatibilityConnectorEntity> compatibleConnectors;
  final List<CompatibilityConnectorEntity> incompatibleConnectors;

  @override
  List<Object?> get props =>
      [isCompatible, vehicle, compatibleConnectors, incompatibleConnectors];
}

/// The vehicle echoed back by the compatibility check.
class CompatibilityVehicleEntity extends Equatable {
  const CompatibilityVehicleEntity({
    required this.id,
    required this.make,
    required this.model,
    required this.connectorType,
  });

  final int id;
  final String make;
  final String model;
  final String connectorType;

  @override
  List<Object?> get props => [id, make, model, connectorType];
}

/// A connector entry under `compatible_connectors` / `incompatible_connectors`.
class CompatibilityConnectorEntity extends Equatable {
  const CompatibilityConnectorEntity({
    required this.id,
    required this.connectorType,
    required this.powerType,
    required this.power,
    required this.connectorState,
    this.connectorId,
  });

  final int id;
  final int? connectorId;
  final String connectorType;
  final String powerType;
  final String power;

  /// `Available`, `Charging`, `Faulted`, etc.
  final String connectorState;

  bool get isAvailable => connectorState.toLowerCase() == 'available';

  @override
  List<Object?> get props =>
      [id, connectorId, connectorType, powerType, power, connectorState];
}
