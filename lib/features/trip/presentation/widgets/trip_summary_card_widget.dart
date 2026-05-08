import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
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

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.mapPinBlueColor.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TripSummaryMetricWidget(
                  icon: Icons.near_me_outlined,
                  label: 'Distance',
                  value: plan == null ? '—' : '${plan!.distanceKm.round()} km',
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: TripSummaryMetricWidget(
                  icon: Icons.schedule_rounded,
                  label: 'Duration',
                  value: plan == null ? '—' : formatDuration(plan!.duration),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: TripSummaryMetricWidget(
                  icon: Icons.bolt_rounded,
                  label: 'Charging Stops',
                  value: '${plan?.stops.length ?? 0}',
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: TripSummaryMetricWidget(
                  icon: Icons.attach_money_rounded,
                  label: 'Total Cost',
                  value: formatPkr(plan?.costPkr ?? 0),
                ),
              ),
            ],
          ),
          14.verticalSpace,
          Container(
            padding: AppUtils.vertical10Horizontal12Padding,
            decoration: BoxDecoration(
              color: ui.efficiencyTipBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 14.sp,
                  color: AppColors.primaryLightColor,
                ),
                8.horizontalSpace,
                Expanded(
                  child: AppText(
                    "You'll save ${plan?.co2SavedKg ?? 0} kg CO₂ compared to petrol vehicles",
                    color: ui.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

