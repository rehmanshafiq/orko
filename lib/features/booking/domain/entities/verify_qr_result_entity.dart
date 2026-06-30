import 'package:equatable/equatable.dart';

/// Result of `POST api/v1/bookings/verify-qr/` — whether the scanned charger
/// QR (charge point + connector) matches the user's approved booking.
///
/// A match comes back `200` with [isMatch] true; a wrong connector comes back
/// `422` with [isMatch] false, the booking auto-flagged disputed server-side,
/// and a [message] telling the user which connector is the correct one.
class VerifyQrResultEntity extends Equatable {
  const VerifyQrResultEntity({
    required this.isMatch,
    this.bookedChargePointId,
    this.bookedConnectorId,
    this.message,
  });

  /// True when the scanned charger matches the booking.
  final bool isMatch;

  /// The charge point / connector the booking is actually for. Useful to point
  /// the user at the right plug when they scanned the wrong one.
  final String? bookedChargePointId;
  final int? bookedConnectorId;

  /// Human-readable message from the backend (e.g. "your correct connector is
  /// 1"). Null when none was provided.
  final String? message;

  @override
  List<Object?> get props => [
        isMatch,
        bookedChargePointId,
        bookedConnectorId,
        message,
      ];
}
