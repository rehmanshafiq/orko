import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

/// Toggle switch whose active track uses the app brand button gradient.
class GradientSwitch extends StatelessWidget {
  const GradientSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.gradientColors,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Active-track gradient colors (top → bottom). Falls back to the app-wide
  /// brand button gradient when null.
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 52.w,
          height: 32.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: value
                ? (gradientColors != null
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors!,
                      )
                    : AppColors.brandButtonGradient)
                : null,
            color: value
                ? null
                : AppColors.greyColor.withValues(alpha: 0.45),
          ),
          padding: EdgeInsets.all(4.r),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.whiteColor
                    : AppColors.iconsGreyColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withValues(alpha: 0.15),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
