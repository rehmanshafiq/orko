import 'package:orko_hubco/features/trip/data/models/trip_json.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_stop_entity.dart';

/// Maps a stop from either the `plan-trip` or the saved-trip payload into the
/// single normalized [TripStopEntity].
class TripStopModel extends TripStopEntity {
  const TripStopModel({
    required super.sequence,
    required super.locationId,
    required super.locationName,
    required super.latitude,
    required super.longitude,
    required super.connectorType,
    required super.connectorPowerKw,
    required super.distanceFromStartKm,
    required super.arrivalSoc,
    required super.departureSoc,
    required super.energyAddedKwh,
    required super.chargingMinutes,
    required super.cost,
    super.locationAddress,
    super.connectorId,
    super.connectorTypeMatchesVehicle,
    super.distanceFromRouteKm,
    super.distanceFromPreviousStopKm,
    super.amenities,
    super.isThirdParty,
  });

  /// `plan-trip` stop shape: `location_id`, `latitude`, `longitude`,
  /// `distance_from_route_km`, `connector_type_matches_vehicle`.
  factory TripStopModel.fromPlanJson(Map<String, dynamic> json) {
    return TripStopModel(
      sequence: TripJson.asInt(json['sequence']),
      locationId: TripJson.asInt(json['location_id']),
      locationName: TripJson.asString(json['location_name']),
      locationAddress: TripJson.asStringOrNull(json['location_address']),
      latitude: TripJson.asDouble(json['latitude']),
      longitude: TripJson.asDouble(json['longitude']),
      connectorId: TripJson.asIntOrNull(json['connector_id']),
      connectorType: TripJson.asString(json['connector_type']),
      connectorTypeMatchesVehicle:
          TripJson.asBool(json['connector_type_matches_vehicle'], fallback: true),
      connectorPowerKw: TripJson.asDouble(json['connector_power_kw']),
      distanceFromStartKm: TripJson.asDouble(json['distance_from_start_km']),
      distanceFromRouteKm: TripJson.asDoubleOrNull(json['distance_from_route_km']),
      distanceFromPreviousStopKm:
          TripJson.asDoubleOrNull(json['distance_from_previous_stop_km']),
      arrivalSoc: TripJson.asDouble(json['arrival_soc']),
      departureSoc: TripJson.asDouble(json['departure_soc']),
      energyAddedKwh: TripJson.asDouble(json['energy_added_kwh']),
      chargingMinutes: TripJson.asDouble(json['charging_minutes']),
      cost: TripJson.asDouble(json['cost']),
      amenities: TripJson.asStringList(json['amenities']),
      isThirdParty: TripJson.asBool(json['is_third_party']),
    );
  }

  /// Saved-trip stop shape: `location`, `location_latitude`,
  /// `location_longitude`, `connector` — omits route distance / match flag.
  factory TripStopModel.fromSavedJson(Map<String, dynamic> json) {
    return TripStopModel(
      sequence: TripJson.asInt(json['sequence']),
      locationId: TripJson.asInt(json['location']),
      locationName: TripJson.asString(json['location_name']),
      locationAddress: TripJson.asStringOrNull(json['location_address']),
      latitude: TripJson.asDouble(json['location_latitude']),
      longitude: TripJson.asDouble(json['location_longitude']),
      connectorId: TripJson.asIntOrNull(json['connector']),
      connectorType: TripJson.asString(json['connector_type']),
      connectorPowerKw: TripJson.asDouble(json['connector_power_kw']),
      distanceFromStartKm: TripJson.asDouble(json['distance_from_start_km']),
      distanceFromPreviousStopKm:
          TripJson.asDoubleOrNull(json['distance_from_previous_stop_km']),
      arrivalSoc: TripJson.asDouble(json['arrival_soc']),
      departureSoc: TripJson.asDouble(json['departure_soc']),
      energyAddedKwh: TripJson.asDouble(json['energy_added_kwh']),
      chargingMinutes: TripJson.asDouble(json['charging_minutes']),
      cost: TripJson.asDouble(json['cost']),
      amenities: TripJson.asStringList(json['amenities']),
      isThirdParty: TripJson.asBool(json['is_third_party']),
    );
  }
}
