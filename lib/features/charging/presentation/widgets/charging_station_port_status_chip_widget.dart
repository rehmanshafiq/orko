import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class ChargingStationPortStatusChipWidget extends StatelessWidget {
  const ChargingStationPortStatusChipWidget({
    super.key,
    required this.available,
  });

  final bool available;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: available
            ? ui.isLight ? AppColors.primaryDarkColor.withValues(alpha: 0.22) : AppColors.primaryDarkColor.withValues(alpha: 0.36)
            : AppColors.slotBusyYellowColor.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: AppText(
        available ? 'Available' : 'Occupied',
        color: available
            ? ui.isLight ? AppColors.primaryDarkColor :  AppColors.primaryLightColor
            : ui.isLight ? AppColors.ratingStarDarkColor: AppColors.ratingStarColor,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }
}
