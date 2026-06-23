import 'package:orko_hubco/features/trip/data/models/trip_json.dart';
import 'package:orko_hubco/features/trip/data/models/trip_stop_model.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/vehicle/data/models/user_vehicle_model.dart';

/// Maps the `body` of `POST /save-trip/`, `GET /trips/` items, and
/// `GET /trips/<id>/`.
class SavedTripModel extends SavedTripEntity {
  const SavedTripModel({
    required super.id,
    required super.originLatitude,
    required super.originLongitude,
    required super.destinationLatitude,
    required super.destinationLongitude,
    required super.startSoc,
    required super.totalDistanceKm,
    required super.totalDriveMinutes,
    required super.totalChargingMinutes,
    required super.totalCost,
    required super.currency,
    required super.status,
    required super.createdAt,
    required super.stops,
    super.vehicle,
    super.originAddress,
    super.destinationAddress,
  });

  factory SavedTripModel.fromJson(Map<String, dynamic> json) {
    final rawVehicle = json['vehicle'];
    final rawStops = json['stops'];
    return SavedTripModel(
      id: TripJson.asInt(json['id']),
      vehicle: rawVehicle is Map
          ? UserVehicleModel.fromJson(Map<String, dynamic>.from(rawVehicle))
          : null,
      originLatitude: TripJson.asDouble(json['origin_latitude']),
      originLongitude: TripJson.asDouble(json['origin_longitude']),
      originAddress: TripJson.asStringOrNull(json['origin_address']),
      destinationLatitude: TripJson.asDouble(json['destination_latitude']),
      destinationLongitude: TripJson.asDouble(json['destination_longitude']),
      destinationAddress: TripJson.asStringOrNull(json['destination_address']),
      startSoc: TripJson.asDouble(json['start_soc']),
      totalDistanceKm: TripJson.asDouble(json['total_distance_km']),
      totalDriveMinutes: TripJson.asDouble(json['total_drive_minutes']),
      totalChargingMinutes: TripJson.asDouble(json['total_charging_minutes']),
      totalCost: TripJson.asDouble(json['total_cost']),
      currency: TripJson.asString(json['currency']),
      status: TripJson.asString(json['status']),
      createdAt: TripJson.asInt(json['created_at']),
      stops: rawStops is List
          ? rawStops
              .whereType<Map>()
              .map((e) =>
                  TripStopModel.fromSavedJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const [],
    );
  }
}
