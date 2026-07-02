import 'package:flutter/foundation.dart';

/// Session-scoped (in-memory) registry of charging-location ids the user has
/// successfully booked in this app session.
///
/// Written by the booking flow when `create-booking` succeeds and read by the
/// Trip planner, which labels a suggested stop's "Pre-book" button as "Booked"
/// when its station id is here. Covers every entry point into booking (the
/// trip Pre-book button, the View Details → Book Slot flow, the map flow).
class BookedStationsSession {
  const BookedStationsSession._();

  /// Booked location ids. A [ValueNotifier] so UI can rebuild on new bookings.
  static final ValueNotifier<Set<int>> ids = ValueNotifier<Set<int>>(<int>{});

  static void markBooked(int locationId) {
    if (ids.value.contains(locationId)) return;
    ids.value = {...ids.value, locationId};
  }

  static bool isBooked(int locationId) => ids.value.contains(locationId);

  static void clear() {
    if (ids.value.isEmpty) return;
    ids.value = <int>{};
  }
}
