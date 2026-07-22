/// Visual style for a time slot in the booking grid (availability).
enum SlotStyle {
  available,
  booked,
  busy,

  /// Outside the station's operating hours — greyed out and non-interactive.
  outOfHours,
}
