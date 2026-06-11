import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/models/slot_style.dart';

class SlotChip extends StatelessWidget {
  const SlotChip({
    super.key,
    required this.ui,
    required this.time,
    required this.style,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final AppUiColors ui;
  final String time;
  final SlotStyle style;
  final double width;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color borderColor;
    late Color textColor;
    List<BoxShadow>? chipShadow;

    switch (style) {
      case SlotStyle.available:
        bg = ui.cardBookingBackground;
        borderColor = isSelected ? ui.brandPrimary : ui.borderSubtle;
        textColor = isSelected
            ? (ui.isLight ? AppColors.blackColor : AppColors.whiteColor)
            : (ui.isLight
                ? ui.brandPrimary
                : AppColors.whiteColor.withValues(alpha: 0.96));
        chipShadow = isSelected
            ? [
                BoxShadow(
                  color: ui.brandPrimary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null;
        break;
      case SlotStyle.booked:
        bg = AppColors.slotBookedBackgroundColor;
        borderColor = ui.isLight
            ? AppColors.slotBookedBackgroundColor.withValues(alpha: 0.2)
            : AppColors.slotBookedBackgroundColor.withValues(alpha: 0.92);
        textColor =
            ui.isLight ? AppColors.whiteColor : AppColors.whiteColor.withValues(alpha: 0.94);
        break;
      case SlotStyle.busy:
        bg = AppColors.slotBusyYellowColor.withValues(alpha: 0.5);
        borderColor = ui.isLight
            ? AppColors.slotBusyYellowColor.withValues(alpha: 0.9)
            : AppColors.slotBusyYellowColor;
        textColor =
            ui.isLight ? AppColors.whiteColor : AppColors.whiteColor.withValues(alpha: 0.94);
        break;
    }

    final interactive = style == SlotStyle.available;

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: interactive ? onTap : null,
        borderRadius: BorderRadius.circular(34.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: width,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(34.r),
            border: Border.all(
              color: borderColor,
              width: style == SlotStyle.available ? (isSelected ? 2 : 1) : 1,
            ),
            boxShadow: chipShadow,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AppText(
                time,
                color: interactive
                    ? textColor.withValues(alpha: isSelected ? 1.0 : 0.94)
                    : textColor.withValues(alpha: 0.92),
                fontSize: FontSizes.font12Sp,
                fontWeight: isSelected && interactive
                    ? FontWeights.weight600
                    : FontWeights.weight500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
