import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/responsive_view_widget.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/view/profile_mobile_view.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ProfileCubit>()..loadProfile()),
        BlocProvider(create: (_) => sl<VehicleCubit>()),
        BlocProvider(create: (_) => sl<ChargingStatsCubit>()..load()),
        // Backs the Charging History list on the Profile tab — reuses the same
        // charge-session-history source as the My Bookings → History tab.
        BlocProvider(create: (_) => sl<MyBookingsCubit>()..loadHistory()),
      ],
      child: const ResponsiveView(
        mobile: ProfileMobileView(),
      ),
    );
  }
}
