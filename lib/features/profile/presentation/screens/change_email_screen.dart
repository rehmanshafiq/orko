import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/usecases/request_email_change_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/verify_email_change_usecase.dart';

/// Number of OTP digits emailed by the backend.
const int _kOtpLength = 6;

/// Two-step email-change flow:
///   1. Enter the new email → `change_email` sends an OTP to it.
///   2. Enter the OTP → `change_email_verify` updates the email.
///
/// Pops the refreshed [UserEntity] on success (the cached user is already
/// updated by the verify call).
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({required this.currentEmail, super.key});

  final String currentEmail;

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

enum _Phase { enterEmail, enterOtp }

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(_kOtpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(_kOtpLength, (_) => FocusNode());

  _Phase _phase = _Phase.enterEmail;
  bool _busy = false;
  String _submittedEmail = '';

  static const int _resendSeconds = 120;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _otpControllers.map((c) => c.text).join();
  bool get _isCodeComplete => _code.length == _kOtpLength;

  String get _formattedRemaining {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  // ── Step 1: request the OTP ────────────────────────────────────────────────

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _busy = true);

    final result = await sl<RequestEmailChangeUseCase>()(
      RequestEmailChangeParams(email: email),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) => AppHelpers.showSnackBar(context, failure.message, isError: true),
      (_) {
        _clearCode();
        setState(() {
          _submittedEmail = email;
          _phase = _Phase.enterOtp;
        });
        _startResendTimer();
        AppHelpers.showSnackBar(context, 'We sent a code to $email.');
      },
    );
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _busy) return;
    // Re-requesting sends a fresh single-use OTP to the same new email.
    setState(() => _busy = true);
    final result = await sl<RequestEmailChangeUseCase>()(
      RequestEmailChangeParams(email: _submittedEmail),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => AppHelpers.showSnackBar(context, failure.message, isError: true),
      (_) {
        _clearCode();
        _startResendTimer();
        AppHelpers.showSnackBar(context, 'A new code was sent to $_submittedEmail.');
      },
    );
  }

  // ── Step 2: verify the OTP ─────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    if (!_isCodeComplete) {
      AppHelpers.showSnackBar(context, 'Please enter the 6-digit code', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final result = await sl<VerifyEmailChangeUseCase>()(
      VerifyEmailChangeParams(otp: _code),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) {
        AppHelpers.showSnackBar(context, failure.message, isError: true);
        _clearCode();
      },
      (user) {
        AppHelpers.showSnackBar(context, 'Your email has been updated.');
        Navigator.of(context).pop(user);
      },
    );
  }

  void _clearCode() {
    for (final c in _otpControllers) {
      c.clear();
    }
    setState(() {});
  }

  void _backToEmail() {
    _timer?.cancel();
    _clearCode();
    setState(() {
      _secondsRemaining = 0;
      _phase = _Phase.enterEmail;
    });
  }

  // ── OTP box behaviour (mirrors the sign-up verify screen) ──────────────────

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      _distribute(value);
      return;
    }
    if (value.isNotEmpty && index < _kOtpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _distribute(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _kOtpLength; i++) {
      _otpControllers[i].text = i < digits.length ? digits[i] : '';
    }
    final lastIndex =
        (digits.length >= _kOtpLength ? _kOtpLength : digits.length) - 1;
    if (lastIndex >= 0) {
      _otpFocusNodes[lastIndex.clamp(0, _kOtpLength - 1)].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _onOtpKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ui.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ui.textPrimary),
          onPressed: () {
            // From the OTP step, back returns to the email step; otherwise close.
            if (_phase == _Phase.enterOtp) {
              _backToEmail();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: AppText(
          'Change Email',
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: SingleChildScrollView(
            padding: AppUtils.horizontal16Padding,
            child: _phase == _Phase.enterEmail
                ? _buildEmailStep(ui)
                : _buildOtpStep(ui),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(AppUiColors ui) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          20.verticalSpace,
          AppText(
            'Enter your new email address. We\'ll send a verification code to '
            'confirm it\'s yours.',
            color: ui.textSecondary,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight400,
          ),
          20.verticalSpace,
          AppText(
            'New Email',
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight600,
          ),
          6.verticalSpace,
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => _requestCode(),
            validator: _validateNewEmail,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
              fontFamily: AppFonts.lexend,
            ),
            cursorColor: ui.brandPrimary,
            decoration: _fieldDecoration(ui, hint: 'new@example.com'),
          ),
          28.verticalSpace,
          _actionButton(
            label: _busy ? 'Sending…' : 'Send Verification Code',
            enabled: !_busy,
            onPress: _requestCode,
          ),
          24.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildOtpStep(AppUiColors ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        20.verticalSpace,
        AppText(
          'Enter the 6-digit code sent to',
          color: ui.textSecondary,
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight400,
        ),
        4.verticalSpace,
        AppText(
          _submittedEmail,
          color: ui.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight700,
        ),
        28.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_kOtpLength, (i) => _buildOtpBox(ui, i)),
        ),
        28.verticalSpace,
        _actionButton(
          label: _busy ? 'Verifying…' : 'Verify & Update',
          enabled: _isCodeComplete && !_busy,
          onPress: _verifyCode,
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
              onTap: (_secondsRemaining > 0 || _busy) ? null : _resendCode,
              behavior: HitTestBehavior.opaque,
              child: AppText(
                _secondsRemaining > 0
                    ? 'Resend in $_formattedRemaining'
                    : 'Resend',
                color: (_secondsRemaining > 0 || _busy)
                    ? ui.textMuted
                    : ui.brandPrimary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ),
          ],
        ),
        16.verticalSpace,
        Center(
          child: GestureDetector(
            onTap: _busy ? null : _backToEmail,
            behavior: HitTestBehavior.opaque,
            child: AppText(
              'Use a different email',
              color: ui.brandPrimary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight600,
            ),
          ),
        ),
        24.verticalSpace,
      ],
    );
  }

  Widget _buildOtpBox(AppUiColors ui, int index) {
    final filled = _otpControllers[index].text.isNotEmpty;
    return SizedBox(
      width: 46.w,
      height: 54.h,
      child: Focus(
        onKeyEvent: (_, event) => _onOtpKey(index, event),
        child: TextFormField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => _onOtpChanged(index, value),
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font20Sp,
            fontWeight: FontWeights.weight700,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: ui.inputFill,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: filled ? ui.brandPrimary : ui.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.brandPrimary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool enabled,
    required VoidCallback onPress,
  }) {
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

  String? _validateNewEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    if (value.toLowerCase() == widget.currentEmail.trim().toLowerCase()) {
      return 'This is already your current email';
    }
    return null;
  }

  InputDecoration _fieldDecoration(AppUiColors ui, {String? hint}) {
    return InputDecoration(
      filled: true,
      fillColor: ui.inputFill,
      isDense: true,
      hintText: hint,
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
}
