import 'package:equatable/equatable.dart';

/// One `{timestamp, value}` point of the session energy graph, where [value]
/// is the cumulative kWh delivered since session start.
class EnergyConsumptionPoint extends Equatable {
  const EnergyConsumptionPoint({required this.timestamp, required this.value});

  /// `yyyy-MM-dd HH:mm:ss` (local server time).
  final String timestamp;
  final double value;

  @override
  List<Object?> get props => [timestamp, value];
}

/// Full details of one completed (or in-progress) charging session, from
/// `GET api/v1/bookings/charge-session-details/?id=<session_id>`.
///
/// The backend substitutes the string `"N/A"` for many fields while data is
/// missing (`completed_at`, `rate`, `avg_power`, cost fields, `co2_reduced_kg`,
/// …), and money/energy figures arrive as decimal strings — so every numeric
/// field is nullable and parsed defensively; render with fallbacks.
class ChargeSessionDetailEntity extends Equatable {
  const ChargeSessionDetailEntity({
    required this.id,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.duration,
    this.energyConsumed,
    this.energyCost,
    this.taxCost,
    this.totalCost,
    this.rate,
    this.avgPower,
    this.startSoc,
    this.endSoc,
    this.co2ReducedKg,
    this.energyConsumptionValues = const [],
    this.locationName,
    this.cityName,
    this.chargePointId,
    this.connectorId,
    this.make,
    this.model,
    this.vehicleRegNo,
  });

  final int id;

  /// Raw status string, e.g. `Completed`, `In-Progress`.
  final String status;

  /// Server timestamps as `yyyy-MM-dd HH:mm:ss` (local). Null when unavailable.
  final String? startedAt;
  final String? completedAt;

  /// Human-readable duration, e.g. `42 min`, `1 hr 5 min`.
  final String? duration;

  /// Energy delivered during the session, in kWh.
  final double? energyConsumed;

  /// Costs in PKR. Null until the backend computes them.
  final double? energyCost;
  final double? taxCost;
  final double? totalCost;

  /// Per-kWh tariff.
  final double? rate;

  /// Average charging power over the session, in kW.
  final double? avgPower;

  /// State-of-charge percentages (0–100). Null until reported.
  final double? startSoc;
  final double? endSoc;

  /// Estimated CO2 avoided vs a petrol car, in kg. Null while the session has
  /// no energy figure yet (backend sends `"N/A"`).
  final double? co2ReducedKg;

  /// Cumulative-kWh graph points; empty when telemetry is unavailable.
  final List<EnergyConsumptionPoint> energyConsumptionValues;

  final String? locationName;
  final String? cityName;
  final String? chargePointId;
  final int? connectorId;

  /// Vehicle info, when a vehicle was attached to the session.
  final String? make;
  final String? model;
  final String? vehicleRegNo;

  /// Best label for the session title, with a sensible fallback.
  String get displayName =>
      (locationName != null && locationName!.trim().isNotEmpty)
          ? locationName!.trim()
          : 'Charging Session';

  @override
  List<Object?> get props => [
        id,
        status,
        startedAt,
        completedAt,
        duration,
        energyConsumed,
        energyCost,
        taxCost,
        totalCost,
        rate,
        avgPower,
        startSoc,
        endSoc,
        co2ReducedKg,
        energyConsumptionValues,
        locationName,
        cityName,
        chargePointId,
        connectorId,
        make,
        model,
        vehicleRegNo,
      ];
}
