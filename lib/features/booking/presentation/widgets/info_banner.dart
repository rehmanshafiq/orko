import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.ui,
    this.message =
        'Arrive 5 minutes early. You can modify or cancel from Bookings before your slot starts.',
  });

  final AppUiColors ui;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryDarkColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDarkColor,
            size: 20.r,
          ),
          10.horizontalSpace,
          Expanded(
            child: AppText(
              message,
              color: ui.textPrimary.withValues(alpha: 0.88),
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
        ],
      ),
    );
  }
}
