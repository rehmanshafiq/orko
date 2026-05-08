import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_route_option_metric_widget.dart';

class TripRouteOptionCardWidget extends StatelessWidget {
  const TripRouteOptionCardWidget({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.stops,
    required this.cost,
    required this.co2,
    required this.leadingIcon,
    required this.leadingIconColor,
    required this.leadingBgColor,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String stops;
  final String cost;
  final String co2;
  final IconData leadingIcon;
  final Color leadingIconColor;
  final Color leadingBgColor;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: AppUtils.vertical10Horizontal12Padding,
        decoration: BoxDecoration(
          color: selected ? ui.efficiencyTipBg : ui.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? AppColors.primaryDarkColor : ui.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: leadingBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(leadingIcon, color: leadingIconColor, size: 20.sp),
                ),
                10.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        color: ui.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                      ),
                      4.verticalSpace,
                      AppText(
                        subtitle,
                        color: ui.textMuted,
                        fontSize: FontSizes.font10Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  8.horizontalSpace,
                  Container(
                    padding: AppUtils.horizontal8Vertical4Padding,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: AppText(
                      'Selected',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font8Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ),
                ],
              ],
            ),
            14.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: TripRouteOptionMetricWidget(
                    label: 'Stops',
                    value: stops,
                    valueColor: ui.textPrimary,
                  ),
                ),
                Expanded(
                  child: TripRouteOptionMetricWidget(
                    label: 'Cost',
                    value: cost,
                    valueColor: AppColors.primaryDarkColor,
                  ),
                ),
                Expanded(
                  child: TripRouteOptionMetricWidget(
                    label: 'CO2 Saved',
                    value: co2,
                    valueColor: AppColors.primaryDarkColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

