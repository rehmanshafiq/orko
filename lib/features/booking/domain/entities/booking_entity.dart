import 'package:equatable/equatable.dart';

/// A booking as returned by the create / reschedule endpoints.
///
/// A freshly created booking on the primary endpoint starts in
/// `pending_approval`; the HGL simplified endpoint returns `approved`.
class BookingEntity extends Equatable {
  const BookingEntity({
    required this.id,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.bookingStatus,
    required this.location,
    this.chargeStation,
    this.chargerConnector,
  });

  final int id;

  /// `YYYY-MM-DD`.
  final String bookingDate;

  /// `HH:mm`.
  final String startTime;

  /// `HH:mm`.
  final String endTime;

  /// e.g. `pending_approval`, `approved`, `cancelled`, `rescheduled`.
  final String bookingStatus;

  final int location;
  final int? chargeStation;
  final int? chargerConnector;

  bool get isApproved => bookingStatus == 'approved';
  bool get isPendingApproval => bookingStatus == 'pending_approval';

  @override
  List<Object?> get props => [
        id,
        bookingDate,
        startTime,
        endTime,
        bookingStatus,
        location,
        chargeStation,
        chargerConnector,
      ];
}
