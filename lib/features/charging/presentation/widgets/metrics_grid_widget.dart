import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/metric_card_widget.dart';

/// All session metrics side by side in a single row.
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
    // IntrinsicHeight bounds the row's height (it's an unbounded ListView
    // child) so the stretched cards can lay out and stay equal-height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) 8.horizontalSpace,
            Expanded(
              child: MetricCardWidget(
                label: metrics[i].label,
                value: metrics[i].value,
                unit: metrics[i].unit,
                icon: metrics[i].icon,
                ui: ui,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
