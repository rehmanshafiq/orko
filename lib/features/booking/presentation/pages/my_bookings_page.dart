import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/responsive_view_widget.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';
import 'package:orko_hubco/features/booking/presentation/view/my_bookings_mobile_view.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  /// Sub-tab the screen should open on for its *next* build. Set by a
  /// notification tap (see PushNotificationService) so the deep link lands on
  /// the right tab, then consumed here on build. Null means the default Active
  /// tab. Pairs with [BottomNavShell.bookingsRefreshTick], which is bumped to
  /// force a rebuild so this value is picked up.
  static BookingTab? pendingInitialTab;

  @override
  Widget build(BuildContext context) {
    // Consume any pending deep-link target; default to Active otherwise.
    final initialTab = pendingInitialTab ?? BookingTab.active;
    pendingInitialTab = null;
    return BlocProvider(
      // Land on [initialTab]; loadBookings() still primes the Upcoming list.
      create: (_) => sl<MyBookingsCubit>()
        ..loadBookings()
        ..selectTab(initialTab),
      child: const ResponsiveView(
        mobile: MyBookingsMobileView(),
      ),
    );
  }
}
