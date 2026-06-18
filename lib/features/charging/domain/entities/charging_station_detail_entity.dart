import 'package:equatable/equatable.dart';

/// Full charging-station detail returned by `api/v1/charging-station/{id}`.
class ChargingStationDetailEntity extends Equatable {
  const ChargingStationDetailEntity({
    required this.locationId,
    required this.name,
    required this.status,
    required this.address,
    required this.contactNumber,
    required this.openingTime,
    required this.closingTime,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    required this.chargers,
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
    this.addressGuide,
  });

  final String locationId;
  final String name;
  final bool status;
  final String address;
  final String? addressGuide;
  final String contactNumber;
  final String openingTime;
  final String closingTime;

  /// Distance from the requesting device, in meters (0 when unknown).
  final double distance;
  final double latitude;
  final double longitude;

  final List<AmenityEntity> amenities;
  final List<ChargerEntity> chargers;

  final double averageRating;
  final int totalReviews;
  final List<StationReviewEntity> reviews;

  /// Flattened list of every connector across all chargers.
  List<ConnectorEntity> get connectors =>
      chargers.expand((charger) => charger.connectors).toList();

  @override
  List<Object?> get props => [
        locationId,
        name,
        status,
        address,
        addressGuide,
        contactNumber,
        openingTime,
        closingTime,
        distance,
        latitude,
        longitude,
        amenities,
        chargers,
        averageRating,
        totalReviews,
        reviews,
      ];
}

class AmenityEntity extends Equatable {
  const AmenityEntity({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  List<Object?> get props => [name, imageUrl];
}

class ChargerEntity extends Equatable {
  const ChargerEntity({
    required this.id,
    required this.model,
    required this.manufacturer,
    required this.status,
    required this.connectors,
    this.type,
    this.connectivityStatus,
  });

  final int id;
  final String model;
  final String manufacturer;
  final String? type;
  final String? connectivityStatus;
  final bool status;
  final List<ConnectorEntity> connectors;

  @override
  List<Object?> get props => [
        id,
        model,
        manufacturer,
        type,
        connectivityStatus,
        status,
        connectors,
      ];
}

class ConnectorEntity extends Equatable {
  const ConnectorEntity({
    required this.id,
    required this.connectorType,
    required this.connectorFormat,
    required this.powerType,
    required this.power,
    required this.connectorState,
    this.connectorId,
    this.price,
  });

  final int id;
  final int? connectorId;
  final String connectorType;
  final String connectorFormat;
  final String powerType;
  final String power;
  final String connectorState;
  final ConnectorPriceEntity? price;

  bool get isAvailable => connectorState.toLowerCase() == 'available';

  @override
  List<Object?> get props => [
        id,
        connectorId,
        connectorType,
        connectorFormat,
        powerType,
        power,
        connectorState,
        price,
      ];
}

class ConnectorPriceEntity extends Equatable {
  const ConnectorPriceEntity({
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

class StationReviewEntity extends Equatable {
  const StationReviewEntity({
    required this.name,
    required this.text,
    required this.rating,
    this.createdAt = '',
    this.profilePicture,
    this.isCurrentUser = false,
  });

  final String name;

  /// Review body (maps to the `description` key from the API).
  final String text;
  final double rating;
  final String createdAt;
  final String? profilePicture;
  final bool isCurrentUser;

  @override
  List<Object?> get props =>
      [name, text, rating, createdAt, profilePicture, isCurrentUser];
}
