import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/mobile/book_slot_mobile_view.dart';

class BookSlotPage extends StatelessWidget {
  const BookSlotPage({
    super.key,
    this.stationName,
    this.stationAddress,
  });

  final String? stationName;
  final String? stationAddress;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingCubit(),
      child: BookSlotMobileView(
        stationName: stationName,
        stationAddress: stationAddress,
      ),
    );
  }
}
