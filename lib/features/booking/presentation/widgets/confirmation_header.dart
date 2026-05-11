import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class ConfirmationHeader extends StatelessWidget {
  const ConfirmationHeader({
    super.key,
    required this.ui,
    this.title = 'Booking Confirmed!',
    this.subtitle =
        'Your charging slot is reserved. A receipt has been sent to your email.',
  });

  final AppUiColors ui;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 88.r,
          width: 88.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryDarkColor.withValues(alpha: 0.2),
            border: Border.all(
              color: AppColors.primaryDarkColor,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppColors.primaryDarkColor,
            size: 48.r,
          ),
        ),
        22.verticalSpace,
        AppText(
          title,
          color: ui.textPrimary,
          fontSize: FontSizes.font24Sp,
          fontWeight: FontWeights.weight700,
          textAlign: TextAlign.center,
        ),
        10.verticalSpace,
        AppText(
          subtitle,
          color: ui.textSecondary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight400,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
