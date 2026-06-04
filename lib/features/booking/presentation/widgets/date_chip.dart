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
    final dayColor = selected ? AppColors.whiteColor : ui.textMuted;
    final dateColor = selected ? AppColors.whiteColor : ui.textSecondary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
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
    );

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: selected ? 44.w : null,
          height: selected ? 44.w : null,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: ui.brandPrimary,
                  shape: BoxShape.circle,
                )
              : null,
          child: content,
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
        ? ui.brandPrimary
        : ui.brandSecondary.withValues(alpha: ui.isLight ? 0.12 : 0.28);

    final labelColor = selected
        ? AppColors.blackColor
        : ui.brandPrimary;

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 52.w,
          height: 52.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: AppText(
            'Today',
            color: labelColor,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
