/// Helpers for comparing booking slots against a station's operating window.
class OperatingHours {
  const OperatingHours({
    required this.openingTime,
    required this.closingTime,
  });

  /// Raw `HH:mm` / `HH:mm:ss` from the station detail API.
  final String openingTime;
  final String closingTime;

  /// True when both bounds are missing/unparseable — treat as unrestricted.
  bool get isUnknown {
    final open = timeToMinutes(openingTime);
    final close = timeToMinutes(closingTime);
    return open == null || close == null;
  }

  /// True for a full-day window (identical open/close, or 00:00–23:59).
  bool get is24Hours {
    final open = timeToMinutes(openingTime);
    final close = timeToMinutes(closingTime);
    if (open == null || close == null) return false;
    if (open == close) return true;
    return open == 0 && close == 24 * 60 - 1;
  }

  /// Whether the slot `[startTime, endTime]` falls fully inside service hours.
  ///
  /// When hours are unknown or 24h, every slot is considered in-service.
  bool containsSlot({
    required String startTime,
    required String endTime,
  }) {
    if (isUnknown || is24Hours) return true;

    final open = timeToMinutes(openingTime)!;
    final close = timeToMinutes(closingTime)!;
    final start = timeToMinutes(startTime);
    final end = timeToMinutes(endTime);
    if (start == null || end == null) return true;

    if (open < close) {
      // Same-day window: slot must start on/after open and end on/before close.
      return start >= open && end <= close;
    }

    // Overnight window (e.g. 22:00 → 06:00): slot sits on the evening side
    // (start ≥ open) or the morning side (end ≤ close).
    return start >= open || end <= close;
  }

  /// Converts `HH:mm` / `HH:mm:ss` into minutes from midnight.
  static int? timeToMinutes(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.isEmpty) return null;
    final hours = int.tryParse(parts[0]);
    if (hours == null) return null;
    final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return hours * 60 + minutes;
  }
}
