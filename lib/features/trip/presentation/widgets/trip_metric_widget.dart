import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripMetricWidget extends StatelessWidget {
  const TripMetricWidget({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Expanded(
      child: Container(
        padding: AppUtils.horizontal8Vertical4Padding,
        decoration: BoxDecoration(
          color: ui.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: ui.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryLightColor, size: 14.sp),
                4.horizontalSpace,
                AppText(
                  value,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ],
            ),
            2.verticalSpace,
            AppText(
              label,
              color: ui.textMuted,
              fontSize: FontSizes.font8Sp,
              fontWeight: FontWeights.weight400,
            ),
          ],
        ),
      ),
    );
  }
}

