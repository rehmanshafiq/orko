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
            ? (ui.isLight ? ui.brandPrimary : AppColors.transparentColor)
                .withValues(alpha: ui.isLight ? 0.22 : 0.36)
            : AppColors.transparentColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: available ? ui.brandSecondary : ui.textMuted)
      ),
      child: AppText(
        available ? 'Available' : 'Occupied',
        color: available
            ? ui.textMuted
            : ui.isLight ? AppColors.ratingStarDarkColor : ui.textMuted,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }
}
