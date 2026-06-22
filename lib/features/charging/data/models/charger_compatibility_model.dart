import 'package:orko_hubco/features/charging/domain/entities/charger_compatibility_entity.dart';

/// Maps the `body` object from
/// `POST api/v1/charging-station/charger-compatibility/`. Parsed defensively.
class ChargerCompatibilityModel extends ChargerCompatibilityEntity {
  const ChargerCompatibilityModel({
    required super.isCompatible,
    required super.compatibleConnectors,
    required super.incompatibleConnectors,
    super.vehicle,
  });

  factory ChargerCompatibilityModel.fromJson(Map<String, dynamic> json) {
    final rawVehicle = json['vehicle'];
    return ChargerCompatibilityModel(
      isCompatible: json['is_compatible'] == true,
      vehicle: rawVehicle is Map
          ? _vehicleFromJson(Map<String, dynamic>.from(rawVehicle))
          : null,
      compatibleConnectors: _connectorList(json['compatible_connectors']),
      incompatibleConnectors: _connectorList(json['incompatible_connectors']),
    );
  }

  static CompatibilityVehicleEntity _vehicleFromJson(
    Map<String, dynamic> json,
  ) {
    return CompatibilityVehicleEntity(
      id: _asInt(json['id']),
      make: (json['make'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      connectorType: (json['connector_type'] ?? '').toString(),
    );
  }

  static List<CompatibilityConnectorEntity> _connectorList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => _connectorFromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  static CompatibilityConnectorEntity _connectorFromJson(
    Map<String, dynamic> json,
  ) {
    return CompatibilityConnectorEntity(
      id: _asInt(json['id']),
      connectorId:
          json['connector_id'] == null ? null : _asInt(json['connector_id']),
      connectorType: (json['connector_type'] ?? '').toString(),
      powerType: (json['power_type'] ?? '').toString(),
      power: (json['power'] ?? '').toString(),
      connectorState: (json['connector_state'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
