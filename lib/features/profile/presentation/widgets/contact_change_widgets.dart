import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/otp_code_field.dart';

/// Number of OTP digits sent for an email/phone change.
const int kContactOtpLength = 6;

/// Full-width primary button used by the change-email / change-phone screens.
class ContactChangeButton extends StatelessWidget {
  const ContactChangeButton({
    required this.label,
    required this.enabled,
    required this.onPress,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return PrimaryButtonWidget(
      text: label,
      onPress: onPress,
      isEnabled: enabled,
      buttonWidth: double.infinity,
      buttonHeight: 48.h,
      cornerRadius: 24.r,
      gradientColors: const [
        AppColors.primaryDarkColor,
        AppColors.primaryDarkButtonColor,
      ],
      textColor: AppColors.whiteColor,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}

/// Input decoration for the new-email / new-phone field. [errorText] shows a
/// server-side rejection (e.g. "already registered") under the field.
InputDecoration contactFieldDecoration(
  AppUiColors ui, {
  String? hint,
  String? prefixText,
  String? errorText,
}) {
  return InputDecoration(
    filled: true,
    fillColor: ui.inputFill,
    isDense: true,
    hintText: hint,
    errorText: errorText,
    errorMaxLines: 2,
    prefixText: prefixText,
    prefixStyle: TextStyle(
      color: ui.textPrimary,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight600,
      fontFamily: AppFonts.lexend,
    ),
    hintStyle: TextStyle(
      color: AppColors.hintColor,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight400,
      fontFamily: AppFonts.lexend,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: ui.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: ui.brandPrimary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: AppColors.redColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: AppColors.redColor),
    ),
    errorStyle: TextStyle(
      color: AppColors.redColor,
      fontSize: FontSizes.font10Sp,
      fontWeight: FontWeights.weight400,
    ),
  );
}

/// Step 2 of a contact change: enter the code sent to [target], with the
/// expiry countdown, a resend link gated by [clock], and a way back to step 1.
class OtpStepView extends StatelessWidget {
  const OtpStepView({
    required this.target,
    required this.codeFieldKey,
    required this.onCodeChanged,
    required this.codeComplete,
    required this.busy,
    required this.clock,
    required this.onVerify,
    required this.onResend,
    required this.changeTargetLabel,
    required this.onChangeTarget,
    super.key,
  });

  final String target;
  final GlobalKey<OtpCodeFieldState> codeFieldKey;
  final ValueChanged<String> onCodeChanged;
  final bool codeComplete;
  final bool busy;
  final OtpRequestClock clock;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final String changeTargetLabel;
  final VoidCallback onChangeTarget;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return ListenableBuilder(
      listenable: clock,
      builder: (context, _) {
        final expired = clock.isExpired;
        final canResend = clock.canRequest && !busy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            20.verticalSpace,
            AppText(
              'Enter the $kContactOtpLength-digit code sent to',
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
            ),
            4.verticalSpace,
            AppText(
              target,
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight700,
            ),
            28.verticalSpace,
            OtpCodeField(
              key: codeFieldKey,
              length: kContactOtpLength,
              onChanged: onCodeChanged,
            ),
            12.verticalSpace,
            AppText(
              expired
                  ? 'This code has expired. Send a new code to continue.'
                  : 'Code expires in '
                      '${formatOtpCountdown(clock.secondsUntilExpiry)}',
              color: expired ? AppColors.removeColor : ui.textMuted,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
              textAlign: TextAlign.center,
            ),
            20.verticalSpace,
            ContactChangeButton(
              label: busy ? 'Verifying…' : 'Verify & Update',
              enabled: codeComplete && !expired && !busy,
              onPress: onVerify,
            ),
            20.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  "Didn't receive the code? ",
                  color: ui.textMuted,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
                GestureDetector(
                  onTap: canResend ? onResend : null,
                  behavior: HitTestBehavior.opaque,
                  child: AppText(
                    clock.canRequest
                        ? 'Send new code'
                        : 'Resend in '
                            '${formatOtpCountdown(clock.secondsUntilResend)}',
                    color: canResend ? ui.brandPrimary : ui.textMuted,
                    fontSize: FontSizes.font12Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            Center(
              child: GestureDetector(
                onTap: busy ? null : onChangeTarget,
                behavior: HitTestBehavior.opaque,
                child: AppText(
                  changeTargetLabel,
                  color: ui.brandPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ),
            ),
            24.verticalSpace,
          ],
        );
      },
    );
  }
}
