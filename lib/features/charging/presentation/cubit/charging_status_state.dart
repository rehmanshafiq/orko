import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';

/// Lifecycle of the live-session fetch that backs the charging-status screen.
enum ChargingStatusViewStatus { initial, loading, success, failure }

/// Session UI mode for the center gauge subtitle.
enum ChargingSessionStatus {
  charging,
  idle,
  emergency,
}

class ChargingMetricDisplay extends Equatable {
  const ChargingMetricDisplay({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  List<Object?> get props => [label, value, unit, icon];
}

/// Drives the charging-status screen, which polls `GET api/v1/bookings/
/// live-session/` every few seconds. The view renders straight off the live
/// [session]; every figure is derived defensively so a partial payload (or no
/// session at all) never throws.
class ChargingStatusState extends Equatable {
  const ChargingStatusState({
    this.status = ChargingStatusViewStatus.initial,
    this.session,
    this.error,
    this.sliderValue = 0.80,
    this.distanceKm = 0,
    this.now,
  });

  /// Backwards-compatible alias kept for callers that constructed the old
  /// hard-coded state.
  factory ChargingStatusState.initial() => const ChargingStatusState();

  final ChargingStatusViewStatus status;

  /// The latest live-session snapshot, or null before the first load.
  final LiveSessionEntity? session;

  final String? error;

  /// Target-charge slider position (0–1). The slider itself is currently
  /// disabled in the UI, but the value is retained for when it returns.
  final double sliderValue;

  /// Distance from nearby-stations API, in kilometers.
  final double distanceKm;

  /// Wall-clock "now" advanced once a second by the cubit's ticker while a
  /// booking countdown is showing. Keeping it in state (rather than calling
  /// DateTime.now() in getters) makes the countdown rebuild exactly once per
  /// tick and keeps the state pure/testable.
  final DateTime? now;

  bool get isLoading => status == ChargingStatusViewStatus.loading;
  bool get isFailure => status == ChargingStatusViewStatus.failure;

  /// True only when the backend reports a running session.
  bool get hasActiveSession => session != null && session!.active;

  ChargingSessionStatus get sessionStatus =>
      hasActiveSession ? ChargingSessionStatus.charging : ChargingSessionStatus.idle;

  String get stationHeadline {
    final name = session?.locationName?.trim();
    return (name != null && name.isNotEmpty) ? name : 'Charging Session';
  }

  double get _chargePercent =>
      (session?.currentChargePercentage ?? 0).clamp(0, 100).toDouble();

  double get gaugeProgress => (_chargePercent / 100).clamp(0.0, 1.0).toDouble();

  String get gaugePercentLabel => '${_chargePercent.round()}%';

  String get statusLabel {
    switch (sessionStatus) {
      case ChargingSessionStatus.charging:
        return 'Charging';
      case ChargingSessionStatus.idle:
        return 'Idle';
      case ChargingSessionStatus.emergency:
        return 'Emergency';
    }
  }

  String get targetPercentLabel => '${(sliderValue * 100).round()}% Target';

  /// "Est. Full Charge in 4m" when the backend reports remaining time.
  String get estimatedTimeLabel {
    final left = session?.timeLeft?.trim();
    if (left == null || left.isEmpty) return 'Estimating time to full…';
    return 'Est. Full Charge in $left';
  }

  /// Whether the live session carries a booked slot to count down against.
  bool get hasBookingCountdown =>
      hasActiveSession && session?.bookingEndDateTime != null;

  /// Live `HH:MM:SS` countdown of the booked slot (ticks via [now]). Empty
  /// when no booking is attached.
  String get bookingTimeLeftLabel {
    if (!hasBookingCountdown) return '';
    final remaining =
        session!.bookingTimeRemaining(now ?? DateTime.now());
    if (remaining == null) return '';
    return _formatDuration(remaining);
  }

  /// True once the booked slot has fully elapsed.
  bool get isBookingSlotOver =>
      hasBookingCountdown &&
      session!.bookingTimeRemaining(now ?? DateTime.now()) == Duration.zero;

  String get stationInfoText => 'Station Info - $stationHeadline';

  /// Operating hours, e.g. `00:00 - 23:59`. Empty when unavailable.
  String get operatingHoursText => session?.operatingHoursLabel ?? '';

  /// Per-unit tariff, e.g. `PKR 98.4 / kwh`. Empty when unavailable.
  String get priceText => session?.priceLabel ?? '';

  /// Dialable contact number, or empty when unavailable.
  String get contactText => session?.fullContactNumber ?? '';

  List<ChargingMetricDisplay> get metrics {
    final energy = session?.energyDeliveredKwh;
    final speed = session?.chargingSpeedKw;
    final time = session?.sessionTime?.trim();
    final cost = session?.currentCost;
    final currency = session?.currency ?? 'PKR';

    return [
      ChargingMetricDisplay(
        label: 'Energy Delivered',
        value: energy != null ? _trimDouble(energy) : '—',
        unit: energy != null ? 'kWh' : '',
        icon: Icons.battery_4_bar_rounded,
      ),
      ChargingMetricDisplay(
        label: 'Charging Speed',
        value: speed != null ? _trimDouble(speed) : '—',
        unit: speed != null ? 'kW' : '',
        icon: Icons.bolt_rounded,
      ),
      ChargingMetricDisplay(
        label: 'Session Time',
        value: (time != null && time.isNotEmpty) ? _formatSessionTime(time) : '—',
        unit: '',
        icon: Icons.access_time_rounded,
      ),
      ChargingMetricDisplay(
        label: 'Current Cost',
        value: cost != null
            ? AppHelpers.formatCurrency(cost, currency: currency)
            : '—',
        unit: '',
        icon: Icons.payments_outlined,
      ),
    ];
  }

  /// [Duration] → `HH:MM:SS` (e.g. 2h 45m 13s → `02:45:13`).
  static String _formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  /// Drops a trailing `.0` so `1.7` stays but `60.0` shows as `60`.
  static String _trimDouble(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  /// Normalises the backend's human duration (e.g. `1h 45m`, `2d 3h 10m`,
  /// `30s`) into `HH:MM:SS`. If it already looks like a clock value (contains
  /// `:`) it's returned untouched.
  static String _formatSessionTime(String raw) {
    if (raw.contains(':')) return raw;

    var totalSeconds = 0;
    final matches = RegExp(r'(\d+)\s*(mo|w|d|h|m|s)', caseSensitive: false)
        .allMatches(raw.toLowerCase());
    for (final match in matches) {
      final value = int.tryParse(match.group(1)!) ?? 0;
      switch (match.group(2)) {
        case 'mo':
          totalSeconds += value * 30 * 24 * 3600;
          break;
        case 'w':
          totalSeconds += value * 7 * 24 * 3600;
          break;
        case 'd':
          totalSeconds += value * 24 * 3600;
          break;
        case 'h':
          totalSeconds += value * 3600;
          break;
        case 'm':
          totalSeconds += value * 60;
          break;
        case 's':
          totalSeconds += value;
          break;
      }
    }

    String two(int n) => n.toString().padLeft(2, '0');
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  ChargingStatusState copyWith({
    ChargingStatusViewStatus? status,
    LiveSessionEntity? session,
    String? error,
    bool clearError = false,
    double? sliderValue,
    double? distanceKm,
    DateTime? now,
  }) {
    return ChargingStatusState(
      status: status ?? this.status,
      session: session ?? this.session,
      error: clearError ? null : (error ?? this.error),
      sliderValue: sliderValue ?? this.sliderValue,
      distanceKm: distanceKm ?? this.distanceKm,
      now: now ?? this.now,
    );
  }

  @override
  List<Object?> get props => [
        status,
        session,
        error,
        sliderValue,
        distanceKm,
        now,
      ];
}
