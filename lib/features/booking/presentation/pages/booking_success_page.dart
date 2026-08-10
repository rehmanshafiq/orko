import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:orko_hubco/features/booking/presentation/mobile/booking_success_mobile_view.dart';

/// Arguments passed to the booking success screen via the router `extra`.
class BookingSuccessArgs extends Equatable {
  const BookingSuccessArgs({
    required this.bookingRef,
    required this.stationName,
    required this.slotLabel,
    required this.amountPaid,
    this.fromTrip = false,
    this.minutesMobile,
  });

  final String bookingRef;
  final String stationName;
  final String slotLabel;
  final int amountPaid;

  /// True when this booking was started from the Trip planner (Pre-book flow).
  /// Closing the success screen then returns to the Trip planner instead of Home.
  final bool fromTrip;

  /// Slot-release grace window (minutes) from the create response
  /// (`minutes_mobile`); null when the backend omits it.
  final int? minutesMobile;

  @override
  List<Object?> get props =>
      [bookingRef, stationName, slotLabel, amountPaid, fromTrip, minutesMobile];
}

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key, required this.args});

  final BookingSuccessArgs args;

  @override
  Widget build(BuildContext context) {
    return BookingSuccessMobileView(
      bookingRef: args.bookingRef,
      stationName: args.stationName,
      slotLabel: args.slotLabel,
      amountPaid: args.amountPaid,
      fromTrip: args.fromTrip,
      minutesMobile: args.minutesMobile,
    );
  }
}
