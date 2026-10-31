import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// Dismissible "update available" prompt for a soft update
/// (`update_available: 1`). Shown by `AppUpdatePrompter`.
class SoftUpdateDialog extends StatelessWidget {
  const SoftUpdateDialog({
    super.key,
    required this.onUpdate,
    required this.onLater,
  });

  final VoidCallback onUpdate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Dialog(
      backgroundColor: ui.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 56.r,
                width: 56.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ui.brandPrimary),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: ui.brandPrimary,
                  size: 28.r,
                ),
              ),
            ),
            16.verticalSpace,
            AppText(
              'Update Available',
              textAlign: TextAlign.center,
              color: ui.textPrimary,
              fontSize: FontSizes.font18Sp,
              fontWeight: FontWeights.weight700,
            ),
            8.verticalSpace,
            AppText(
              'A new version of the app is available with the latest '
              'improvements and fixes.',
              textAlign: TextAlign.center,
              color: ui.textMuted,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
            ),
            20.verticalSpace,
            PrimaryButtonWidget(
              text: 'Update',
              onPress: onUpdate,
              buttonHeight: 40.h,
              cornerRadius: 24.r,
              // Same dark-green gradient as the station detail "Book Slot" button.
              gradientColors: const [
                AppColors.primaryDarkColor,
                AppColors.primaryDarkButtonColor,
              ],
              textColor: AppColors.whiteColor,
              fontSize: FontSizes.font15Sp,
              fontWeight: FontWeights.weight700,
            ),
            4.verticalSpace,
            TextButton(
              onPressed: onLater,
              child: AppText(
                'Later',
                color: ui.textMuted,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
