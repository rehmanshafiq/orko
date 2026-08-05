import 'package:equatable/equatable.dart';

class StationPriceEntity extends Equatable {
  const StationPriceEntity({
    required this.pricingMode,
    required this.currency,
    required this.price,
  });

  final String pricingMode;
  final String currency;
  final double price;

  @override
  List<Object?> get props => [pricingMode, currency, price];
}

class HubcoLocationEntity extends Equatable {
  final int id;
  final String name;

  /// Human-friendly title from the map API `display_name` key. Empty when the
  /// API omits it (the card then falls back to [name]).
  final String displayName;
  final String address;

  /// Area/locality from the charging-station map API (e.g. `F11`).
  final String area;

  /// City from the charging-station map API (e.g. `Islamabad`).
  final String city;
  final double latitude;
  final double longitude;
  final bool status;

  /// Distance from the requesting device, in kilometers (0 when unknown).
  final double distance;

  /// Remote station icon URL (with background) when provided by the API.
  final String iconUrl;

  final int numberOfConnectors;
  final int availableConnectors;

  /// Whether the station currently has an available connector (`available`).
  final bool available;

  /// Power/connector kinds from the `type` array, e.g. `['DC']`, `['AC', 'AC/DC']`.
  final List<String> connectorTypes;

  /// Peak power outputs in kW from the `power` array, e.g. `[60]`.
  final List<double> powerOutputs;

  final List<StationPriceEntity> prices;

  const HubcoLocationEntity({
    required this.id,
    required this.name,
    this.displayName = '',
    required this.address,
    this.area = '',
    this.city = '',
    required this.latitude,
    required this.longitude,
    required this.status,
    this.distance = 0,
    this.iconUrl = '',
    this.numberOfConnectors = 0,
    this.availableConnectors = 0,
    this.available = false,
    this.connectorTypes = const [],
    this.powerOutputs = const [],
    this.prices = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        address,
        area,
        city,
        latitude,
        longitude,
        status,
        distance,
        iconUrl,
        numberOfConnectors,
        availableConnectors,
        available,
        connectorTypes,
        powerOutputs,
        prices,
      ];
}
