import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Week row pill (Mon–Sat).
class DateChip extends StatelessWidget {
  const DateChip({
    super.key,
    required this.ui,
    required this.day,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final AppUiColors ui;
  final String day;
  final String date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = selected
        ? AppColors.primaryDarkColor.withValues(alpha: 0.95)
        : ui.cardBackground;
    final borderColor =
        selected ? AppColors.primaryDarkColor : ui.borderSubtle;
    final dayColor = selected ? AppColors.whiteColor : ui.textMuted;
    final dateColor = selected ? AppColors.whiteColor : ui.textSecondary;

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDarkColor
                          .withValues(alpha: ui.isLight ? 0.12 : 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                day,
                color: dayColor,
                fontSize: FontSizes.font10Sp,
                fontWeight:
                    selected ? FontWeights.weight600 : FontWeights.weight500,
              ),
              4.verticalSpace,
              AppText(
                date,
                color: dateColor,
                fontSize: FontSizes.font12Sp,
                fontWeight:
                    selected ? FontWeights.weight700 : FontWeights.weight600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular "Today" chip (segment index 0).
class TodayDateChip extends StatelessWidget {
  const TodayDateChip({
    super.key,
    required this.ui,
    required this.selected,
    required this.onTap,
  });

  final AppUiColors ui;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    /// Unselected circle: translucent primary on dark, tinted surface on light
    /// so contrast stays WCAG-ish for caption text without white-on-muted.
    final bg = selected
        ? AppColors.primaryDarkColor.withValues(alpha: 0.95)
        : ui.isLight
            ? AppColors.primaryDarkColor.withValues(alpha: 0.12)
            : AppColors.primaryDarkColor.withValues(alpha: 0.28);

    final labelColor =
        selected ? AppColors.whiteColor : ui.isLight ? AppColors.primaryDarkColor : AppColors.whiteColor;

    final borderColor = selected
        ? ui.isLight
            ? AppColors.primaryDarkColor.withValues(alpha: 0.72)
            : AppColors.primaryLightColor.withValues(alpha: 0.55)
        : ui.borderSubtle;

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 50.w,
          height: 50.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDarkColor
                          .withValues(alpha: ui.isLight ? 0.28 : 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: AppText(
            'Today',
            color: labelColor,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
