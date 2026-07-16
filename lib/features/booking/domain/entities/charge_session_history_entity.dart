import 'package:equatable/equatable.dart';

/// A single charging session row from
/// `GET api/v1/bookings/charge-session-history/`.
///
/// In-progress sessions have a null [completedAt] and null cost/energy fields,
/// which only get populated once the session completes — so every numeric field
/// is nullable and must be rendered defensively.
class ChargeSessionHistoryEntity extends Equatable {
  const ChargeSessionHistoryEntity({
    required this.id,
    required this.locationName,
    required this.status,
    this.bookingId,
    this.startedAt,
    this.completedAt,
    this.duration,
    this.energyConsumed,
    this.energyCost,
    this.taxCost,
    this.totalCost,
  });

  final int id;
  final String locationName;

  /// `booking_id` of the reservation this session belongs to. Null when the
  /// user charged without a booking — a walk-in session (see [isWalkIn]).
  final int? bookingId;

  /// Raw status string, e.g. `In-Progress`, `Completed`.
  final String status;

  /// Server timestamps as `yyyy-MM-dd HH:mm:ss` (local). Null when unavailable.
  final String? startedAt;
  final String? completedAt;

  /// Human-readable duration, e.g. `16m`, `1mo 1w 6d 13h 24m`.
  final String? duration;

  final double? energyConsumed;
  final double? energyCost;
  final double? taxCost;
  final double? totalCost;

  /// Normalises the status (strips spaces/hyphens/case) for safe comparison.
  String get _normalizedStatus =>
      status.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');

  bool get isInProgress => _normalizedStatus == 'inprogress';
  bool get isCompleted => _normalizedStatus == 'completed';

  /// A walk-in session has no associated booking (charged without reserving).
  bool get isWalkIn => bookingId == null;

  /// Best label for the row title — the location, with a sensible fallback.
  String get displayName =>
      locationName.trim().isNotEmpty ? locationName.trim() : 'Charging Session';

  @override
  List<Object?> get props => [
        id,
        locationName,
        status,
        bookingId,
        startedAt,
        completedAt,
        duration,
        energyConsumed,
        energyCost,
        taxCost,
        totalCost,
      ];
}
