import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_metric_widget.dart';

class TripEvDetailsCardWidget extends StatelessWidget {
  const TripEvDetailsCardWidget({
    required this.currentBatteryPercent,
    super.key,
  });

  final double currentBatteryPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const TripMetricWidget(
              icon: Icons.electric_car_rounded,
              value: 'BYD',
              label: 'Atto 3',
            ),
            8.horizontalSpace,
            const TripMetricWidget(
              icon: Icons.route_rounded,
              value: '280 km',
              label: 'range',
            ),
          ],
        ),
        12.verticalSpace,
        Row(
          children: [
            TripMetricWidget(
              icon: Icons.battery_6_bar_rounded,
              value: '${currentBatteryPercent.round()}%',
              label: 'current charge',
            ),
          ],
        ),
      ],
    );
  }
}

