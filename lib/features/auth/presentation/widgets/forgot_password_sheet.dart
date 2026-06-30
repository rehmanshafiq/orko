import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/forgot_password_state.dart';

const int _kOtpLength = 6;

/// Three-step forgot-password flow shown as a modal sheet: request an OTP by
/// email, verify the code, then choose a new password.
class ForgotPasswordSheet {
  const ForgotPasswordSheet._();

  /// Opens the flow. Resolves to the success message when the password was
  /// reset, or null if the user dismissed the sheet.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (_) => BlocProvider(
        create: (_) => sl<ForgotPasswordCubit>(),
        child: const _ForgotPasswordView(),
      ),
    );
  }
}

enum _Step { email, otp, password }

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(_kOtpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(_kOtpLength, (_) => FocusNode());

  _Step _step = _Step.email;
  int? _otpId;
  String? _accessToken;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  AutovalidateMode _emailAutovalidate = AutovalidateMode.disabled;
  AutovalidateMode _passwordAutovalidate = AutovalidateMode.disabled;

  static const int _resendSeconds = 120;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otp.length == _kOtpLength;

  String get _formattedRemaining {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
    if (mounted) setState(() {});
  }

  void _submitEmail() {
    FocusScope.of(context).unfocus();
    final isValid = _emailFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _emailAutovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    context.read<ForgotPasswordCubit>().requestOtp(_emailController.text.trim());
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();
    if (!_isOtpComplete) {
      AppHelpers.showSnackBar(context, 'Please enter the 6-digit code',
          isError: true);
      return;
    }
    final otpId = _otpId;
    if (otpId == null) {
      AppHelpers.showSnackBar(
        context,
        'Something went wrong. Please request a new code.',
        isError: true,
      );
      return;
    }
    context.read<ForgotPasswordCubit>().verifyOtp(otpId: otpId, otp: _otp);
  }

  void _resend() {
    if (_secondsRemaining > 0) return;
    final cubit = context.read<ForgotPasswordCubit>();
    if (cubit.state is ForgotPasswordSendingOtp) return;
    FocusScope.of(context).unfocus();
    cubit.requestOtp(_emailController.text.trim());
  }

  void _submitReset() {
    FocusScope.of(context).unfocus();
    final isValid = _passwordFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _passwordAutovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'Your verification expired. Please start again.',
        isError: true,
      );
      return;
    }
    context.read<ForgotPasswordCubit>().resetPassword(
          accessToken: token,
          newPassword: _passwordController.text,
          confirmPassword: _confirmController.text,
        );
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _kOtpLength; i++) {
        _otpControllers[i].text = i < digits.length ? digits[i] : '';
      }
      final last = (digits.length >= _kOtpLength ? _kOtpLength : digits.length) - 1;
      if (last >= 0) {
        _otpFocusNodes[last.clamp(0, _kOtpLength - 1)].requestFocus();
      }
      setState(() {});
      return;
    }
    if (value.isNotEmpty && index < _kOtpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
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
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordOtpSent) {
          _otpId = state.otpId;
          _clearOtp();
          setState(() => _step = _Step.otp);
          _startResendTimer();
          AppHelpers.showSnackBar(
            context,
            'We sent a 6-digit code to ${state.email}',
          );
        } else if (state is ForgotPasswordOtpVerified) {
          _accessToken = state.accessToken;
          _timer?.cancel();
          setState(() => _step = _Step.password);
        } else if (state is ForgotPasswordSuccess) {
          // Hand the message back so the login screen can confirm it.
          Navigator.of(context).pop(state.message);
        } else if (state is ForgotPasswordError) {
          AppHelpers.showSnackBar(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        final Widget body;
        switch (_step) {
          case _Step.email:
            body = _buildEmailStep(ui, state is ForgotPasswordSendingOtp);
            break;
          case _Step.otp:
            body = _buildOtpStep(ui, state is ForgotPasswordVerifyingOtp);
            break;
          case _Step.password:
            body = _buildPasswordStep(ui, state is ForgotPasswordResetting);
            break;
        }
        return Padding(
          // Lift the sheet above the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ui.scaffoldBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
            child: SingleChildScrollView(child: body),
          ),
        );
      },
    );
  }

  Widget _buildHandle(AppUiColors ui) {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: ui.inputBorder,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }

  // ── Step 1: email ───────────────────────────────────────────────────────
  Widget _buildEmailStep(AppUiColors ui, bool isSending) {
    return Form(
      key: _emailFormKey,
      autovalidateMode: _emailAutovalidate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(ui),
          AppText(
            'Forgot Password',
            color: ui.textPrimary,
            fontSize: FontSizes.font20Sp,
            fontWeight: FontWeights.weight700,
          ),
          6.verticalSpace,
          AppText(
            'Enter the email linked to your account and we\'ll send you a code '
            'to reset your password.',
            color: ui.textMuted,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight400,
          ),
          20.verticalSpace,
          AppText(
            'Email',
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
          8.verticalSpace,
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: AppHelpers.validateEmail,
            onFieldSubmitted: (_) => _submitEmail(),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
            ),
            decoration: _inputDecoration(
              ui: ui,
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.mail_outline,
                  color: AppColors.hintColor, size: 20),
            ),
          ),
          24.verticalSpace,
          _primaryButton(
            text: isSending ? 'Sending...' : 'Send Code',
            isEnabled: !isSending,
            onPress: _submitEmail,
          ),
          8.verticalSpace,
        ],
      ),
    );
  }

  // ── Step 2: verify OTP ──────────────────────────────────────────────────
  Widget _buildOtpStep(AppUiColors ui, bool isVerifying) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(ui),
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _step = _Step.email),
              child: Icon(Icons.arrow_back, color: ui.textPrimary, size: 22.sp),
            ),
            10.horizontalSpace,
            AppText(
              'Verify Code',
              color: ui.textPrimary,
              fontSize: FontSizes.font20Sp,
              fontWeight: FontWeights.weight700,
            ),
          ],
        ),
        6.verticalSpace,
        AppText(
          'Enter the 6-digit code we sent to ${_emailController.text.trim()}.',
          color: ui.textMuted,
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight400,
        ),
        24.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_kOtpLength, (i) => _buildOtpBox(ui, i)),
        ),
        14.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              "Didn't get the code? ",
              color: ui.textMuted,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
            GestureDetector(
              onTap: _secondsRemaining > 0 ? null : _resend,
              child: AppText(
                _secondsRemaining > 0 ? 'Resend in $_formattedRemaining' : 'Resend',
                color: _secondsRemaining > 0 ? ui.textMuted : ui.brandPrimary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ),
          ],
        ),
        24.verticalSpace,
        _primaryButton(
          text: isVerifying ? 'Verifying...' : 'Verify',
          isEnabled: _isOtpComplete && !isVerifying,
          onPress: _verifyOtp,
        ),
        8.verticalSpace,
      ],
    );
  }

  // ── Step 3: new password ────────────────────────────────────────────────
  Widget _buildPasswordStep(AppUiColors ui, bool isResetting) {
    return Form(
      key: _passwordFormKey,
      autovalidateMode: _passwordAutovalidate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(ui),
          AppText(
            'New Password',
            color: ui.textPrimary,
            fontSize: FontSizes.font20Sp,
            fontWeight: FontWeights.weight700,
          ),
          6.verticalSpace,
          AppText(
            'Choose a new password for your account.',
            color: ui.textMuted,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight400,
          ),
          20.verticalSpace,
          AppText(
            'New Password',
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
          8.verticalSpace,
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: AppHelpers.validatePassword,
            maxLength: 40,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
            ),
            decoration: _inputDecoration(
              ui: ui,
              hintText: 'New password',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.hintColor,
                  size: 20,
                ),
              ),
            ),
          ),
          4.verticalSpace,
          AppText(
            'Confirm Password',
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
          8.verticalSpace,
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            maxLength: 40,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitReset(),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
            ),
            decoration: _inputDecoration(
              ui: ui,
              hintText: 'Re-enter new password',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.hintColor,
                  size: 20,
                ),
              ),
            ),
          ),
          16.verticalSpace,
          _primaryButton(
            text: isResetting ? 'Resetting...' : 'Reset Password',
            isEnabled: !isResetting,
            onPress: _submitReset,
          ),
          8.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildOtpBox(AppUiColors ui, int index) {
    final filled = _otpControllers[index].text.isNotEmpty;
    return SizedBox(
      width: 44.w,
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

  Widget _primaryButton({
    required String text,
    required bool isEnabled,
    required VoidCallback onPress,
  }) {
    return PrimaryButtonWidget(
      text: text,
      onPress: onPress,
      isEnabled: isEnabled,
      buttonHeight: 40.h,
      cornerRadius: 24.r,
      gradientColors: const [
        AppColors.primaryDarkColor,
        AppColors.primaryDarkButtonColor,
      ],
      textColor: AppColors.whiteColor,
      fontSize: FontSizes.font16Sp,
      fontWeight: FontWeights.weight600,
    );
  }

  InputDecoration _inputDecoration({
    required AppUiColors ui,
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      counterText: '',
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.hintColor,
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: ui.inputFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ui.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ui.brandPrimary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redColor),
      ),
    );
  }
}
