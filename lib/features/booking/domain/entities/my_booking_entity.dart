import 'package:equatable/equatable.dart';

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

  bool get isRescheduledCopy => reschedule == 1;

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
      ];
}
