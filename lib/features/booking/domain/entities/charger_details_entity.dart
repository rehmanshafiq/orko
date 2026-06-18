import 'package:equatable/equatable.dart';

/// Tariff for a connector.
class PortPriceEntity extends Equatable {
  const PortPriceEntity({
    required this.pricingMode,
    required this.currency,
    required this.price,
  });

  /// e.g. `per_kwh`.
  final String pricingMode;

  /// e.g. `PKR`.
  final String currency;

  /// Unit price (per kWh when [pricingMode] is `per_kwh`).
  final double price;

  bool get isPerKwh => pricingMode.toLowerCase() == 'per_kwh';

  @override
  List<Object?> get props => [pricingMode, currency, price];
}

/// A single charger connector/port at a location.
class ChargerPortEntity extends Equatable {
  const ChargerPortEntity({
    required this.id,
    required this.name,
    required this.connectorType,
    required this.connectorState,
    this.price,
  });

  final int id;
  final String name;

  /// e.g. `CCS2`, `CCS`, `Type 2`.
  final String connectorType;

  /// e.g. `Available`, `Preparing`, `Faulted`, `Charging`.
  final String connectorState;

  /// Connector tariff, when provided by the API.
  final PortPriceEntity? price;

  /// Only `Available` connectors can be selected/booked.
  bool get isAvailable => connectorState.toLowerCase() == 'available';

  @override
  List<Object?> get props => [id, name, connectorType, connectorState, price];
}

/// Charger details for a location: station info + its connectors.
class ChargerDetailsEntity extends Equatable {
  const ChargerDetailsEntity({
    required this.stationName,
    required this.stationAddress,
    required this.ports,
  });

  final String stationName;
  final String stationAddress;
  final List<ChargerPortEntity> ports;

  @override
  List<Object?> get props => [stationName, stationAddress, ports];
}
