import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

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
    this.bookingDate,
    this.bookingStartTime,
    this.bookingEndTime,
    this.paymentMethod,
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

  /// Booking slot, from the nested `booking` object. Date is `yyyy-MM-dd`;
  /// times are `HH:mm:ss` (24-hour). Null when no booking was attached.
  final String? bookingDate;
  final String? bookingStartTime;
  final String? bookingEndTime;

  /// Raw payment method, e.g. `cash`, `card`. Null when unavailable.
  final String? paymentMethod;

  /// Booking slot formatted for the receipt, e.g. "July 21 – 3:30 pm – 4:00
  /// pm". Null when no booking date is available.
  String? get bookingSlotLabel {
    final date = bookingDate;
    if (date == null || date.trim().isEmpty) return null;
    final parsedDate = DateTime.tryParse(date.trim());
    final datePart =
        parsedDate != null ? DateFormat('MMMM d').format(parsedDate) : date.trim();
    final start = _formatClock(bookingStartTime);
    final end = _formatClock(bookingEndTime);
    if (start != null && end != null) return '$datePart – $start – $end';
    if (start != null) return '$datePart – $start';
    return datePart;
  }

  /// Human-readable payment method for the receipt, e.g. "Cash". Null when
  /// unavailable.
  String? get paymentMethodLabel {
    final method = paymentMethod?.trim();
    if (method == null || method.isEmpty) return null;
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
      case 'credit':
      case 'debit':
      case 'credit/debit':
        return 'Credit/Debit Card';
      default:
        return method[0].toUpperCase() + method.substring(1);
    }
  }

  /// Formats a `HH:mm:ss` clock string as "3:30 pm". Null when unparseable.
  static String? _formatClock(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a')
        .format(dt)
        .replaceAll('AM', 'am')
        .replaceAll('PM', 'pm');
  }

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
        bookingDate,
        bookingStartTime,
        bookingEndTime,
        paymentMethod,
      ];
}
