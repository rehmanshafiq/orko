import 'package:equatable/equatable.dart';

/// A single 30-minute charging slot returned by the slots API.
///
/// [isAvailable] is `false` when either every connector at the location is
/// taken for this slot, or the logged-in user already holds an active booking
/// in it. The UI greys those out.
class BookingSlotEntity extends Equatable {
  const BookingSlotEntity({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  /// `HH:mm`, e.g. `09:00`.
  final String startTime;

  /// `HH:mm`, e.g. `09:30`. Must be sent back verbatim when booking.
  final String endTime;

  final bool isAvailable;

  @override
  List<Object?> get props => [startTime, endTime, isAvailable];
}
