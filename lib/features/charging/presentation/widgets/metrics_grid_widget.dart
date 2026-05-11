import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/metric_card_widget.dart';

class MetricsGridWidget extends StatelessWidget {
  const MetricsGridWidget({
    super.key,
    required this.metrics,
    required this.ui,
  });

  final List<ChargingMetricDisplay> metrics;
  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCardWidget(
                label: m[0].label,
                value: m[0].value,
                unit: m[0].unit,
                icon: m[0].icon,
                ui: ui,
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: MetricCardWidget(
                label: m[1].label,
                value: m[1].value,
                unit: m[1].unit,
                icon: m[1].icon,
                ui: ui,
              ),
            ),
          ],
        ),
        8.verticalSpace,
        Row(
          children: [
            Expanded(
              child: MetricCardWidget(
                label: m[2].label,
                value: m[2].value,
                unit: m[2].unit,
                icon: m[2].icon,
                ui: ui,
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: MetricCardWidget(
                label: m[3].label,
                value: m[3].value,
                unit: m[3].unit,
                icon: m[3].icon,
                ui: ui,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
