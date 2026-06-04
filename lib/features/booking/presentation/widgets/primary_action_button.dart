import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_revamped_theme.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    this.text = 'Start Charge',
  });

  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              t.bookSlotDarkGreen,
              t.bookSlotPrimaryGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: t.bookSlotPrimaryGreen.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparentColor,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24.r),
            child: Center(
              child: AppText(
                text,
                color: t.textOnBrand,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
