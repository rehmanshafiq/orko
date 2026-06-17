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
  final String address;
  final double latitude;
  final double longitude;
  final bool status;

  /// Distance from the requesting device, in kilometers (0 when unknown).
  final double distance;

  /// Remote station icon URL (with background) when provided by the API.
  final String iconUrl;

  final int numberOfConnectors;
  final int availableConnectors;
  final List<StationPriceEntity> prices;

  const HubcoLocationEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.distance = 0,
    this.iconUrl = '',
    this.numberOfConnectors = 0,
    this.availableConnectors = 0,
    this.prices = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        status,
        distance,
        iconUrl,
        numberOfConnectors,
        availableConnectors,
        prices,
      ];
}
