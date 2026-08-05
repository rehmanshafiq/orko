import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// Prompts a guest user to log in or sign up before performing an action that
/// requires an authenticated account (e.g. booking a slot).
class AuthRequiredDialog {
  AuthRequiredDialog._();

  /// Shows the prompt. Returns once the dialog is dismissed.
  ///
  /// [feature] identifies the gated capability the guest was blocked from
  /// (e.g. booking/notifications/support/vehicle/profile/trip/favorites/
  /// reviews) and is reported to analytics as the guest→register conversion
  /// driver. [title]/[message] can be overridden per call site; defaults suit
  /// booking.
  static Future<void> show(
    BuildContext context, {
    required String feature,
    String title = 'Login Required',
    String message =
        'You\'re browsing as a guest. Please log in or create an account to book a charging slot.',
  }) {
    sl<AnalyticsService>().logEvent(
      'auth_required_prompt',
      parameters: {'feature': feature},
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _AuthRequiredDialogBody(
        title: title,
        message: message,
        onLogin: () {
          Navigator.of(dialogContext).pop();
          context.go('/login');
        },
        onSignUp: () {
          Navigator.of(dialogContext).pop();
          context.go('/register');
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

class _AuthRequiredDialogBody extends StatelessWidget {
  const _AuthRequiredDialogBody({
    required this.title,
    required this.message,
    required this.onLogin,
    required this.onSignUp,
    required this.onCancel,
  });

  final String title;
  final String message;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final VoidCallback onCancel;

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
                  border: Border.all(color: ui.brandPrimary)
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: ui.brandPrimary,
                  size: 28.r,
                ),
              ),
            ),
            16.verticalSpace,
            AppText(
              title,
              textAlign: TextAlign.center,
              color: ui.textPrimary,
              fontSize: FontSizes.font18Sp,
              fontWeight: FontWeights.weight700,
            ),
            8.verticalSpace,
            AppText(
              message,
              textAlign: TextAlign.center,
              color: ui.textMuted,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
            ),
            20.verticalSpace,
            PrimaryButtonWidget(
              text: 'Login',
              onPress: onLogin,
              buttonHeight: 40.h,
              cornerRadius: 24.r,
              gradientColors: const [
                AppColors.primaryDarkColor,
                AppColors.primaryDarkButtonColor,
              ],
              textColor: AppColors.whiteColor,
              fontSize: FontSizes.font15Sp,
              fontWeight: FontWeights.weight600,
            ),
            12.verticalSpace,
            PrimaryButtonWidget(
              text: 'Sign Up',
              onPress: onSignUp,
              buttonHeight: 40.h,
              cornerRadius: 24.r,
              strokeColor: ui.brandPrimary,
              buttonColor: AppColors.transparentColor,
              textColor: ui.brandPrimary,
              fontSize: FontSizes.font15Sp,
              fontWeight: FontWeights.weight600,
            ),
            4.verticalSpace,
            TextButton(
              onPressed: onCancel,
              child: AppText(
                'Maybe later',
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
