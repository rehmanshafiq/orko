import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_summary_metric_widget.dart';

class TripSummaryCardWidget extends StatelessWidget {
  const TripSummaryCardWidget({
    required this.plan,
    required this.formatDuration,
    required this.formatPkr,
    super.key,
  });

  final TripPlanModel? plan;
  final String Function(Duration) formatDuration;
  final String Function(int) formatPkr;

  String _formatTotalTime(Duration duration) {
    final formatted = formatDuration(duration);
    if (formatted.endsWith('m') && !formatted.endsWith('min')) {
      return '${formatted.substring(0, formatted.length - 1)}min';
    }
    return formatted;
  }

  String _formatChargingCost(int amount) {
    // `formatPkr` already yields the `Rs. 1,456` style used across the flow.
    return formatPkr(amount);
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
      decoration: const BoxDecoration(
        color: AppColors.transparentColor,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TripSummaryMetricWidget(
                icon: Icons.add_location_alt_outlined,
                label: 'Total Distance:',
                value: plan == null ? '—' : '${plan!.distanceKm.round()} km',
              ),
            ),
            _SummarySectionDivider(color: ui.borderSubtle),
            Expanded(
              child: TripSummaryMetricWidget(
                icon: Icons.schedule_rounded,
                label: 'Total Time:',
                value: plan == null ? '—' : _formatTotalTime(plan!.duration),
              ),
            ),
            _SummarySectionDivider(color: ui.borderSubtle),
            Expanded(
              child: TripSummaryMetricWidget(
                icon: Icons.payments_outlined,
                label: 'Total Charging Cost:',
                value: plan == null ? '—' : _formatChargingCost(plan!.costPkr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySectionDivider extends StatelessWidget {
  const _SummarySectionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      color: color,
    );
  }
}
