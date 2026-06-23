import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_stop_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';

/// Result of `POST /trip-planning/plan-trip/` — an optimised, non-persisted plan.
///
/// [feasible] `false` is still a successful response: it means the trip can't be
/// completed with the available enroute chargers, and [stops] holds the partial
/// route reached. The accompanying message should be shown as a warning.
class TripPlanEntity extends Equatable {
  const TripPlanEntity({
    required this.feasible,
    required this.startSoc,
    required this.rangeKm,
    required this.connectorType,
    required this.totalDistanceKm,
    required this.totalDriveMinutes,
    required this.totalChargingMinutes,
    required this.totalCost,
    required this.currency,
    required this.numberOfStops,
    required this.stops,
    this.vehicle,
    this.batteryCapacityKwh,
    this.message,
  });

  final UserVehicleEntity? vehicle;
  final bool feasible;
  final double startSoc;
  final double rangeKm;
  final double? batteryCapacityKwh;
  final String connectorType;
  final double totalDistanceKm;
  final double totalDriveMinutes;
  final double totalChargingMinutes;
  final double totalCost;
  final String currency;
  final int numberOfStops;
  final List<TripStopEntity> stops;

  /// Warning text when [feasible] is `false`.
  final String? message;

  @override
  List<Object?> get props => [
        vehicle,
        feasible,
        startSoc,
        rangeKm,
        batteryCapacityKwh,
        connectorType,
        totalDistanceKm,
        totalDriveMinutes,
        totalChargingMinutes,
        totalCost,
        currency,
        numberOfStops,
        stops,
        message,
      ];
}
