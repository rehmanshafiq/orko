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
  });

  final String bookingRef;
  final String stationName;
  final String slotLabel;
  final int amountPaid;

  @override
  List<Object?> get props => [bookingRef, stationName, slotLabel, amountPaid];
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
    );
  }
}
