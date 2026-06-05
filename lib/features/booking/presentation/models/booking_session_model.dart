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

/// A finished session shown under the "History" tab.
class HistoryBooking {
  const HistoryBooking({
    required this.stationName,
    required this.dateTimeLabel,
    required this.relativeLabel,
    required this.energyKwh,
    required this.statusLabel,
    required this.amount,
  });

  final String stationName;
  final String dateTimeLabel;
  final String relativeLabel;
  final double energyKwh;
  final String statusLabel;
  final double amount;
}
