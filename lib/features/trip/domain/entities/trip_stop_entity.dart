import 'package:equatable/equatable.dart';

/// A single charging stop on a planned or saved trip.
///
/// Normalises the two slightly different stop shapes the API returns:
/// the `plan-trip` stop uses `location_id` / `latitude` / `longitude` /
/// `distance_from_route_km` / `connector_type_matches_vehicle`; the saved-trip
/// stop uses `location` / `location_latitude` / `location_longitude` /
/// `connector` and omits the route-distance and connector-match flags.
class TripStopEntity extends Equatable {
  const TripStopEntity({
    required this.sequence,
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.connectorType,
    required this.connectorPowerKw,
    required this.distanceFromStartKm,
    required this.arrivalSoc,
    required this.departureSoc,
    required this.energyAddedKwh,
    required this.chargingMinutes,
    required this.cost,
    this.locationAddress,
    this.connectorId,
    this.connectorTypeMatchesVehicle = true,
    this.distanceFromRouteKm,
    this.distanceFromPreviousStopKm,
    this.amenities = const [],
  });

  final int sequence;
  final int locationId;
  final String locationName;
  final String? locationAddress;
  final double latitude;
  final double longitude;
  final int? connectorId;
  final String connectorType;

  /// Only present on `plan-trip` stops; defaults to `true` for saved stops.
  final bool connectorTypeMatchesVehicle;
  final double connectorPowerKw;
  final double distanceFromStartKm;

  /// Only present on `plan-trip` stops.
  final double? distanceFromRouteKm;

  /// Distance (km) from the previous stop on the route.
  final double? distanceFromPreviousStopKm;
  final double arrivalSoc;
  final double departureSoc;
  final double energyAddedKwh;
  final double chargingMinutes;
  final double cost;

  /// Amenities available at the stop, e.g. `['Wifi', 'Air Conditioner']`.
  final List<String> amenities;

  @override
  List<Object?> get props => [
        sequence,
        locationId,
        locationName,
        locationAddress,
        latitude,
        longitude,
        connectorId,
        connectorType,
        connectorTypeMatchesVehicle,
        connectorPowerKw,
        distanceFromStartKm,
        distanceFromRouteKm,
        distanceFromPreviousStopKm,
        arrivalSoc,
        departureSoc,
        energyAddedKwh,
        chargingMinutes,
        cost,
        amenities,
      ];
}
