import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/responsive_view_widget.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/view/my_bookings_mobile_view.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyBookingsCubit>()..loadBookings(),
      child: const ResponsiveView(
        mobile: MyBookingsMobileView(),
      ),
    );
  }
}
