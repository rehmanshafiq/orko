import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// Shared confirmation dialog used across the profile screen (delete account,
/// remove photo, delete vehicle, permission prompts). Returns `true` when the
/// user confirms.
Future<bool?> showProfileConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  required String confirmText,
  double? buttonHeight,
  double? buttonRadius,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
    builder: (_) => ProfileConfirmDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      confirmText: confirmText,
      buttonHeight: buttonHeight,
      buttonRadius: buttonRadius,
    ),
  );
}

class ProfileConfirmDialog extends StatelessWidget {
  const ProfileConfirmDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmText,
    this.buttonHeight,
    this.buttonRadius,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmText;
  final double? buttonHeight;
  final double? buttonRadius;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final height = buttonHeight ?? 42.h;
    final radius = buttonRadius ?? 12.r;
    return Dialog(
      backgroundColor: ui.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      child: Padding(
        padding: AppUtils.all18Padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22.r),
                ),
                12.horizontalSpace,
                Expanded(
                  child: AppText(
                    title,
                    color: ui.textPrimary,
                    fontSize: FontSizes.font18Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
            14.verticalSpace,
            AppText(
              message,
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
              height: 1.4,
            ),
            22.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'Cancel',
                    onPress: () => Navigator.of(context).pop(false),
                    buttonWidth: double.infinity,
                    buttonHeight: height,
                    cornerRadius: radius,
                    buttonColor: ui.chipInactiveBg,
                    strokeColor: ui.borderSubtle,
                    textColor: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: PrimaryButtonWidget(
                    text: confirmText,
                    onPress: () => Navigator.of(context).pop(true),
                    buttonWidth: double.infinity,
                    buttonHeight: height,
                    cornerRadius: radius,
                    gradientColors: const [
                      AppColors.primaryDarkColor,
                      AppColors.primaryDarkButtonColor,
                    ],
                    textColor: AppColors.whiteColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
