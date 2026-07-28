import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';

/// The title + body text for the live-charging notification, plus a compact map
/// used to drive the iOS Live Activity. Kept UI-free so it can be built in the
/// foreground-service background isolate as well as on the main isolate.
class LiveChargingNotificationContent {
  const LiveChargingNotificationContent({
    required this.title,
    required this.text,
    required this.data,
  });

  final String title;
  final String text;

  /// Flattened figures for the iOS Live Activity channel (all strings).
  final Map<String, String> data;
}

/// Builds the notification content for an *in-progress* session, mirroring the
/// figures shown on the My Charging → Live tab (station, charge %, energy,
/// session time, cost) with a music-player-style progress bar for a "live" feel.
LiveChargingNotificationContent buildActiveContent(LiveSessionEntity s) {
  final station = s.displayName;
  final pct = s.currentChargePercentage;
  final energy = _kwh(s.energyDeliveredKwh);
  final time = _clean(s.sessionTime);
  final cost = _cost(s.currentCost, s.currency);

  final pctLabel = pct == null ? null : '${pct.round()}%';
  final bar = pct == null ? null : _progressBar(pct);

  // Text: "▰▰▰▰▱▱ 62%  ·  3.4 kWh  ·  0h 12m  ·  PKR 120"
  final parts = <String>[
    if (bar != null && pctLabel != null) '$bar $pctLabel' else 'Charging',
    if (energy != null) energy,
    if (time != null) time,
    if (cost != null) cost,
  ];

  return LiveChargingNotificationContent(
    title: '⚡ $station',
    text: parts.join('  ·  '),
    data: {
      'state': 'active',
      'station': station,
      'percent': pctLabel ?? '',
      'percentValue': pct == null ? '' : pct.clamp(0, 100).toString(),
      'energy': energy ?? '',
      'time': time ?? '',
      'cost': cost ?? '',
      'isWalkin': s.isWalkinSession.toString(),
    },
  );
}

/// Builds the terminal "Charging Complete" content shown once the session ends.
/// Dismissible (unlike the ongoing content) and carries the final totals.
LiveChargingNotificationContent buildCompletedContent(LiveSessionEntity? s) {
  final station = s?.displayName ?? 'Charging Session';
  final energy = _kwh(s?.energyDeliveredKwh ?? s?.kwhDelivered);
  final cost = _cost(s?.currentCost ?? s?.totalCost, s?.currency);

  final parts = <String>[
    station,
    if (energy != null) energy,
    if (cost != null) cost,
  ];

  return LiveChargingNotificationContent(
    title: 'Charging Complete',
    text: parts.join('  ·  '),
    data: {
      'state': 'completed',
      'station': station,
      'energy': energy ?? '',
      'cost': cost ?? '',
    },
  );
}

/// A 10-segment unicode progress bar for [percent] (0–100), e.g. `▰▰▰▰▰▱▱▱▱▱`.
String _progressBar(double percent) {
  const segments = 10;
  final filled = (percent.clamp(0, 100) / 100 * segments).round();
  return '${'▰' * filled}${'▱' * (segments - filled)}';
}

String? _kwh(double? value) {
  if (value == null) return null;
  final rounded = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return '$rounded kWh';
}

/// `PKR 120` / `PKR 98.40`, tolerant of a missing currency. UI-free (no intl
/// locale lookups) so it is isolate-safe.
String? _cost(double? amount, String? currency) {
  if (amount == null) return null;
  final unit = (currency != null && currency.trim().isNotEmpty)
      ? currency.trim()
      : 'PKR';
  final value = amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
  return '$unit $value';
}

String? _clean(String? raw) {
  final value = raw?.trim();
  return (value == null || value.isEmpty) ? null : value;
}
