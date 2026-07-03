import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';

class TripRouteSuggestionCardWidget extends StatelessWidget {
  const TripRouteSuggestionCardWidget({
    required this.fastestPlan,
    required this.economicalPlan,
    super.key,
  });

  final TripPlanModel? fastestPlan;
  final TripPlanModel? economicalPlan;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final saving = (fastestPlan != null && economicalPlan != null)
        ? (fastestPlan!.costPkr - economicalPlan!.costPkr)
        : 0;
    final hasMeaningfulSaving = saving > 0;
    final message = hasMeaningfulSaving
        ? 'Consider the economical route to save ${AppHelpers.formatRs(saving)} on the fastest route for a more enjoyable journey with better amenities.'
        : 'Both routes are similar in cost. Pick the one that best fits your schedule.';

    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.chargingPatternsBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: ui.chargingPatternsBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.info_outline_rounded,
              size: 15.sp,
              color: AppColors.mapPinBlueColor,
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Route Suggestions',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight700,
                ),
                4.verticalSpace,
                AppText(
                  message,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font10Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

