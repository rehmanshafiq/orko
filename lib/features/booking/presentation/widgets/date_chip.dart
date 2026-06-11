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
    final borderColor = selected ? ui.brandPrimary : ui.borderSubtle;
    final dayColor = ui.textMuted;
    final dateColor = selected
        ? (ui.isLight ? AppColors.blackColor : AppColors.whiteColor)
        : ui.textSecondary;

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
          width: 44.w,
          height: 44.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ui.cardBookingBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ui.brandPrimary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
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
    final borderColor = selected ? ui.brandPrimary : ui.borderSubtle;
    final labelColor = ui.textMuted;

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
            color: ui.cardBookingBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ui.brandPrimary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
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
