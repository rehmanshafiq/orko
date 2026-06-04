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
    late Color border;
    late Color textColor;

    switch (style) {
      case SlotStyle.available:
        if (ui.isLight) {
          bg = AppColors.primaryDarkColor.withValues(alpha: 0.1);
          border = AppColors.primaryDarkColor.withValues(alpha: 0.42);
          textColor = AppColors.primaryDarkColor;
        } else {
          bg = AppColors.primaryDarkColor.withValues(alpha: 0.28);
          border = AppColors.primaryDarkColor.withValues(alpha: 0.75);
          textColor = AppColors.whiteColor.withValues(alpha: 0.96);
        }
        break;
      case SlotStyle.booked:
        bg = AppColors.slotBookedBackgroundColor;
        border = ui.isLight
            ? AppColors.slotBookedBackgroundColor.withValues(alpha: 0.2)
            : AppColors.slotBookedBackgroundColor.withValues(alpha: 0.92);
        textColor =
            ui.isLight ? AppColors.whiteColor : AppColors.whiteColor.withValues(alpha: 0.94);
        break;
      case SlotStyle.busy:
        bg = AppColors.slotBusyYellowColor.withValues(alpha: 0.5);
        border = ui.isLight
            ? AppColors.slotBusyYellowColor.withValues(alpha: 0.9)
            : AppColors.slotBusyYellowColor;
        textColor =
            ui.isLight ? AppColors.whiteColor : AppColors.whiteColor.withValues(alpha: 0.94);
        break;
    }

    List<BoxShadow>? chipShadow;

    if (isSelected && style == SlotStyle.available) {
      bg = AppColors.primaryDarkColor;
      border = ui.isLight
          ? AppColors.primaryDarkColor.withValues(alpha: 0.95)
          : AppColors.primaryLightColor.withValues(alpha: 0.72);
      textColor = AppColors.blackColor;
      chipShadow = [
        BoxShadow(
          color:
              AppColors.primaryDarkColor.withValues(alpha: ui.isLight ? 0.35 : 0.5),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
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
              color: border,
              width: style == SlotStyle.available ? (isSelected ? 2 : 1.25) : 1,
            ),
            boxShadow: chipShadow,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: interactive && isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(
                        //   Icons.check_circle_rounded,
                        //   size: 13.sp,
                        //   color: AppColors.whiteColor.withValues(alpha: 0.95),
                        // ),
                        // 3.horizontalSpace,
                        AppText(
                          time,
                          color: textColor,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight600,
                        ),
                      ],
                    )
                  : AppText(
                      time,
                      color: interactive
                          ? textColor.withValues(alpha: isSelected ? 1.0 : 0.94)
                          : textColor.withValues(alpha: 0.92),
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight500,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
