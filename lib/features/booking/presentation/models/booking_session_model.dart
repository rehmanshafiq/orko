/// Tabs shown on the My Bookings screen.
enum BookingTab { active, upcoming, history }

extension BookingTabX on BookingTab {
  String get label {
    switch (this) {
      case BookingTab.active:
        return 'Active';
      case BookingTab.upcoming:
        return 'Upcoming';
      case BookingTab.history:
        return 'History';
    }
  }
}

/// Sub-tabs within the Upcoming tab, filtering the my-bookings list by
/// `booking_status` (`approved`, `cancelled`).
enum UpcomingFilter { approved, cancelled }

extension UpcomingFilterX on UpcomingFilter {
  String get label {
    switch (this) {
      case UpcomingFilter.approved:
        return 'Approved';
      case UpcomingFilter.cancelled:
        return 'Cancelled';
    }
  }
}

/// An in-progress charging session shown under the "Active" tab.
class ActiveSession {
  const ActiveSession({
    required this.stationName,
    required this.powerLabel,
    required this.startedAtLabel,
    required this.energyDeliveredKwh,
    required this.progressPercent,
  });

  final String stationName;
  final String powerLabel;
  final String startedAtLabel;
  final double energyDeliveredKwh;

  /// 0.0 – 1.0 charge progress.
  final double progressPercent;
}

/// A reserved, not-yet-started booking shown under the "Upcoming" tab.
class UpcomingBooking {
  const UpcomingBooking({
    required this.stationName,
    required this.powerLabel,
    required this.statusLabel,
    required this.dateTimeLabel,
    required this.durationLabel,
    required this.estimatedCost,
  });

  final String stationName;
  final String powerLabel;
  final String statusLabel;
  final String dateTimeLabel;
  final String durationLabel;
  final num estimatedCost;
}

/// A charging session shown under the "History" tab, built from
/// `charge-session-history/`. Covers both completed and in-progress sessions,
/// so the energy/cost figures are nullable (they only populate on completion).
class HistoryBooking {
  const HistoryBooking({
    required this.stationName,
    required this.dateTimeLabel,
    required this.durationLabel,
    required this.statusLabel,
    required this.isInProgress,
    this.energyKwh,
    this.amount,
  });

  final String stationName;

  /// Formatted "started at" timestamp, or a placeholder when unavailable.
  final String dateTimeLabel;

  /// Human-readable session duration, e.g. `16m`.
  final String durationLabel;

  final String statusLabel;

  /// In-progress sessions are styled differently and hide cost/energy.
  final bool isInProgress;

  /// kWh delivered — null until the session completes.
  final double? energyKwh;

  /// Total cost — null until the session completes.
  final double? amount;
}
