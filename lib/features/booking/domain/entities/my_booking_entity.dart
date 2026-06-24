import 'package:equatable/equatable.dart';

/// Connector info for a booking (`charger_info`), null when no connector data.
class BookingChargerInfoEntity extends Equatable {
  const BookingChargerInfoEntity({
    required this.connectorType,
    required this.powerType,
    required this.power,
  });

  /// e.g. `CCS2`, `Type 2`.
  final String connectorType;

  /// `ac` or `dc`.
  final String powerType;

  /// e.g. `60.0 kW`.
  final String power;

  @override
  List<Object?> get props => [connectorType, powerType, power];
}

/// Estimated cost for a booking (`estimated_cost`), null when no rate configured.
class BookingCostEntity extends Equatable {
  const BookingCostEntity({
    required this.amount,
    required this.currency,
    required this.pricingMode,
  });

  /// `power_kW × duration_hours × price_per_kWh`.
  final double amount;
  final String currency;
  final String pricingMode;

  @override
  List<Object?> get props => [amount, currency, pricingMode];
}

/// A booking row from `my-charging-sessions/` (approved + cancelled bookings).
class MyBookingEntity extends Equatable {
  const MyBookingEntity({
    required this.id,
    required this.stationName,
    required this.locationName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.bookingStatus,
    required this.bookingCode,
    required this.locationId,
    required this.locationLat,
    required this.locationLong,
    required this.currentChargeState,
    required this.desireChargeState,
    required this.reschedule,
    required this.canReschedule,
    required this.canCancel,
    this.chargerInfo,
    this.estimatedCost,
  });

  final int id;
  final String stationName;
  final String locationName;
  final String date;
  final String startTime;
  final String endTime;
  final String bookingStatus;
  final String bookingCode;
  final int locationId;
  final double locationLat;
  final double locationLong;
  final num? currentChargeState;
  final num? desireChargeState;

  /// `1` means this booking is itself a rescheduled version of another.
  final int reschedule;
  final bool canReschedule;
  final bool canCancel;
  final BookingChargerInfoEntity? chargerInfo;
  final BookingCostEntity? estimatedCost;

  bool get isRescheduledCopy => reschedule == 1;
  bool get isApproved => bookingStatus.toLowerCase() == 'approved';
  bool get isCancelled => bookingStatus.toLowerCase() == 'cancelled';
  bool get isPendingApproval =>
      bookingStatus.toLowerCase() == 'pending_approval';

  /// Hubco locations have a null `station_name`; fall back to `location_name`.
  String get displayName =>
      stationName.isNotEmpty ? stationName : locationName;

  @override
  List<Object?> get props => [
        id,
        stationName,
        locationName,
        date,
        startTime,
        endTime,
        bookingStatus,
        bookingCode,
        locationId,
        locationLat,
        locationLong,
        currentChargeState,
        desireChargeState,
        reschedule,
        canReschedule,
        canCancel,
        chargerInfo,
        estimatedCost,
      ];
}
