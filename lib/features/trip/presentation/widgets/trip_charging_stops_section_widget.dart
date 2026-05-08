import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stops_timeline_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_section_title_widget.dart';

class TripChargingStopsSectionWidget extends StatelessWidget {
  const TripChargingStopsSectionWidget({
    required this.plan,
    required this.currentBatteryPercent,
    required this.targetArrivalBatteryPercent,
    required this.expandedChargingStopIndex,
    required this.onToggleChargingStop,
    required this.onViewDetails,
    required this.onPreBook,
    required this.formatPkr,
    super.key,
  });

  final TripPlanModel? plan;
  final double currentBatteryPercent;
  final double targetArrivalBatteryPercent;
  final int? expandedChargingStopIndex;
  final ValueChanged<int> onToggleChargingStop;
  final ValueChanged<int> onViewDetails;
  final VoidCallback onPreBook;
  final String Function(int) formatPkr;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final lineColor = AppColors.primaryDarkColor.withValues(alpha: ui.isLight ? 0.42 : 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TripSectionTitleWidget(text: 'Charging Stops'),
        14.verticalSpace,
        if (plan == null)
          AppText(
            'Plan a trip to see charging stops along your route.',
            color: ui.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
          )
        else
          TripChargingStopsTimelineWidget(
            plan: plan!,
            lineColor: lineColor,
            currentBatteryPercent: currentBatteryPercent,
            targetArrivalBatteryPercent: targetArrivalBatteryPercent,
            expandedChargingStopIndex: expandedChargingStopIndex,
            onToggleChargingStop: onToggleChargingStop,
            onViewDetails: onViewDetails,
            onPreBook: onPreBook,
            formatPkr: formatPkr,
          ),
      ],
    );
  }
}

