import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_confirmation_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/mobile/booking_confirmation_mobile_view.dart';

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({
    super.key,
    this.amountPaid = 472,
  });

  final int amountPaid;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingConfirmationCubit(amountPaid: amountPaid),
      child: const BookingConfirmationMobileView(),
    );
  }
}
