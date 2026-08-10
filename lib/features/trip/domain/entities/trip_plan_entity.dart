import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_savings_entity.dart';
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
    this.savings,
    this.message,
    this.planType,
  });

  final UserVehicleEntity? vehicle;

  /// Echoes the planning mode the server ran (`"optimized"` | `"all_stations"`);
  /// null on older responses that predate the field.
  final String? planType;

  /// `true` when this is an all-stations browse result. In that mode every
  /// charging-simulation field ([feasible], [startSoc], [totalCost],
  /// [totalChargingMinutes], [currency], [savings], and each stop's SoC / cost /
  /// energy / charging-minutes) is absent server-side — do not display them.
  bool get isAllStations => planType == 'all_stations';

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

  /// Fuel-cost and CO₂ savings for the trip; null when the API omits it.
  final TripSavingsEntity? savings;

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
        savings,
        message,
        planType,
      ];
}
