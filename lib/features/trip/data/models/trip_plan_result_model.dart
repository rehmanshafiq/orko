import 'package:orko_hubco/features/trip/data/models/trip_json.dart';
import 'package:orko_hubco/features/trip/data/models/trip_savings_model.dart';
import 'package:orko_hubco/features/trip/data/models/trip_stop_model.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_plan_entity.dart';
import 'package:orko_hubco/features/vehicle/data/models/user_vehicle_model.dart';

/// Maps the `body` of `POST /trip-planning/plan-trip/`.
///
/// Named `…ResultModel` to avoid colliding with the existing presentation-layer
/// `TripPlanModel` consumed by the map/stops/summary widgets.
class TripPlanResultModel extends TripPlanEntity {
  const TripPlanResultModel({
    required super.feasible,
    required super.startSoc,
    required super.rangeKm,
    required super.connectorType,
    required super.totalDistanceKm,
    required super.totalDriveMinutes,
    required super.totalChargingMinutes,
    required super.totalCost,
    required super.currency,
    required super.numberOfStops,
    required super.stops,
    super.vehicle,
    super.batteryCapacityKwh,
    super.savings,
    super.message,
  });

  factory TripPlanResultModel.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    final rawVehicle = json['vehicle'];
    final rawStops = json['stops'];
    final rawSavings = json['savings'];
    return TripPlanResultModel(
      vehicle: rawVehicle is Map
          ? UserVehicleModel.fromJson(Map<String, dynamic>.from(rawVehicle))
          : null,
      feasible: TripJson.asBool(json['feasible'], fallback: true),
      startSoc: TripJson.asDouble(json['start_soc']),
      rangeKm: TripJson.asDouble(json['range_km']),
      batteryCapacityKwh: TripJson.asDoubleOrNull(json['battery_capacity_kwh']),
      connectorType: TripJson.asString(json['connector_type']),
      totalDistanceKm: TripJson.asDouble(json['total_distance_km']),
      totalDriveMinutes: TripJson.asDouble(json['total_drive_minutes']),
      totalChargingMinutes: TripJson.asDouble(json['total_charging_minutes']),
      totalCost: TripJson.asDouble(json['total_cost']),
      currency: TripJson.asString(json['currency']),
      numberOfStops: TripJson.asInt(json['number_of_stops']),
      stops: rawStops is List
          ? rawStops
              .whereType<Map>()
              .map((e) =>
                  TripStopModel.fromPlanJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const [],
      savings: rawSavings is Map
          ? TripSavingsModel.fromJson(Map<String, dynamic>.from(rawSavings))
          : null,
      message: message,
    );
  }
}
