import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import '../../../../core/utils/responsive_view_widget.dart';
import '../cubit/charging_status_cubit.dart';
import '../view/charging_status_mobile_view.dart';

class ChargingStatusPage extends StatelessWidget {
  const ChargingStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChargingStatusCubit>()..start(),
      child: const ResponsiveView(
        mobile: ChargingStatusMobileView(),
      ),
    );
  }
}
