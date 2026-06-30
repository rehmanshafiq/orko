import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

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
    this.sessionTime,
    this.energyDeliveredKwh,
    this.chargingSpeedKw,
    this.currentChargePercentage,
    this.currentCost,
    this.timeLeft,
    this.openingTime,
    this.closingTime,
    this.contactNumber,
    this.countryCode,
    this.pricingMode,
    this.currency,
    this.price,
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

  // ── Live charging telemetry (richer `live-session` payload) ─────────────
  // These are populated by the in-progress live-session response that powers
  // the full charging-status screen. They stay null in the leaner payloads.

  /// Human-readable session duration, e.g. `1h 45m`.
  final String? sessionTime;

  /// Energy delivered so far, in kWh.
  final double? energyDeliveredKwh;

  /// Instantaneous charging speed, in kW.
  final double? chargingSpeedKw;

  /// Current battery state-of-charge (0–100).
  final double? currentChargePercentage;

  /// Cost accrued so far, in the session [currency].
  final double? currentCost;

  /// Human-readable time remaining, e.g. `4m`.
  final String? timeLeft;

  /// Station operating hours as `HH:mm:ss` strings. Null when unavailable.
  final String? openingTime;
  final String? closingTime;

  /// Station contact, split into a dialing [countryCode] and local number.
  final String? contactNumber;
  final String? countryCode;

  /// Tariff: how the price is charged (e.g. `kwh`), the [currency], and the
  /// per-unit [price].
  final String? pricingMode;
  final String? currency;
  final double? price;

  /// Best label for the session title, with a sensible fallback.
  String get displayName => (locationName != null && locationName!.trim().isNotEmpty)
      ? locationName!.trim()
      : 'Charging Session';

  /// Full dialable contact, e.g. `+923332724753`, or null when unavailable.
  String? get fullContactNumber {
    final number = contactNumber?.trim();
    if (number == null || number.isEmpty) return null;
    final code = countryCode?.trim();
    return (code != null && code.isNotEmpty) ? '$code$number' : number;
  }

  /// `12:00 AM - 11:59 PM` style operating-hours label (am/pm), or null when
  /// unavailable.
  String? get operatingHoursLabel {
    final open = _formatTime(openingTime);
    final close = _formatTime(closingTime);
    if (open == null && close == null) return null;
    return '${open ?? '—'} - ${close ?? '—'}';
  }

  /// Per-unit tariff label, e.g. `PKR 98.4 / kWh`, or null when unavailable.
  String? get priceLabel {
    if (price == null) return null;
    final unit = (currency != null && currency!.trim().isNotEmpty)
        ? currency!.trim()
        : '';
    final mode = (pricingMode != null && pricingMode!.trim().isNotEmpty)
        ? ' / ${pricingMode!.trim()}'
        : '';
    final amount =
        price == price!.roundToDouble() ? price!.toInt().toString() : '$price';
    return '$unit $amount$mode'.trim();
  }

  /// `HH:mm:ss` (24h) → `h:mm a` (e.g. `00:00:00` → `12:00 AM`), leaving
  /// anything unparseable untouched.
  static String? _formatTime(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;
    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
  }

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
        sessionTime,
        energyDeliveredKwh,
        chargingSpeedKw,
        currentChargePercentage,
        currentCost,
        timeLeft,
        openingTime,
        closingTime,
        contactNumber,
        countryCode,
        pricingMode,
        currency,
        price,
      ];
}
