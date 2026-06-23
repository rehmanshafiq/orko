import 'package:equatable/equatable.dart';

/// The user's currently-running charging session, from
/// `GET api/v1/bookings/live-session/`.
///
/// When [active] is false the body carries only that flag, so every other
/// field is nullable. While a session is in progress the SOC/energy/cost
/// figures stay null until the backend computes them — render defensively.
class LiveSessionEntity extends Equatable {
  const LiveSessionEntity({
    required this.active,
    this.sessionId,
    this.locationName,
    this.startedAt,
    this.elapsed,
    this.startSoc,
    this.endSoc,
    this.kwhDelivered,
    this.energyCost,
    this.totalCost,
  });

  /// No live session — the empty/idle state.
  const LiveSessionEntity.inactive() : this(active: false);

  /// Whether a charging session is currently running.
  final bool active;

  final int? sessionId;
  final String? locationName;

  /// Server timestamp as `yyyy-MM-dd HH:mm:ss` (local). Null when unavailable.
  final String? startedAt;

  /// Human-readable elapsed time, e.g. `1mo 2w 4d 6h 17m`.
  final String? elapsed;

  /// State-of-charge percentages (0–100). Null until reported.
  final double? startSoc;
  final double? endSoc;

  final double? kwhDelivered;
  final double? energyCost;
  final double? totalCost;

  /// Best label for the session title, with a sensible fallback.
  String get displayName => (locationName != null && locationName!.trim().isNotEmpty)
      ? locationName!.trim()
      : 'Charging Session';

  @override
  List<Object?> get props => [
        active,
        sessionId,
        locationName,
        startedAt,
        elapsed,
        startSoc,
        endSoc,
        kwhDelivered,
        energyCost,
        totalCost,
      ];
}
