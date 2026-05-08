import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripMapLabelChipWidget extends StatelessWidget {
  const TripMapLabelChipWidget({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: ui.isLight
            ? AppColors.whiteColor.withValues(alpha: 0.85)
            : AppColors.blackColor.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: AppText(
        text,
        color: ui.textPrimary.withValues(alpha: 0.88),
        fontSize: FontSizes.font8Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}

