import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/otp_input_formatter.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';

/// Number of OTP digits.
const int _kOtpLength = 6;

/// 6-digit OTP verification screen, shown after a successful sign-up.
class VerifyOtpScreen extends StatefulWidget {
  /// Full phone number (without country code) the code was sent to.
  final String phoneNumber;

  /// Dialing code, e.g. `+92`.
  final String countryCode;

  /// Pending OTP id for the sign-in flow. When null (the signup flow), resend
  /// authorizes with the saved access token instead of an id.
  final String? otpId;

  /// When true, Resend is enabled immediately instead of after the countdown —
  /// used when returning to a pending verification on a later app launch,
  /// where the original code may already have expired.
  final bool resendAvailable;

  const VerifyOtpScreen({
    super.key,
    required this.phoneNumber,
    this.countryCode = '+92',
    this.otpId,
    this.resendAvailable = false,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  // A single hidden field holds the whole code and the six boxes only render
  // it. Moving focus between separate fields per digit makes iOS tear down and
  // re-attach the input connection, which bounces the keyboard on every key.
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const int _resendSeconds = 120;
  int _secondsRemaining = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.resendAvailable) {
      _secondsRemaining = 0;
    } else {
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  String get _code => _controller.text;

  bool get _isComplete => _code.length == _kOtpLength;

  /// Countdown formatted as `m:ss`, e.g. `2:00`, `1:05`, `0:09`.
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

  void _onChanged(String value) {
    setState(() {});
    _submitIfComplete();
  }

  /// Verifies automatically once every box is filled (last digit typed or a
  /// full code pasted), unless a verification is already in flight.
  void _submitIfComplete() {
    if (!_isComplete) return;
    if (context.read<AuthCubit>().state is OtpVerifying) return;
    _onVerify();
  }

  void _onVerify() {
    if (!_isComplete) {
      AppHelpers.showSnackBar(
        context,
        'Please enter the 6-digit code',
        isError: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    // otpId is null for post-signup verification and set for the OTP sign-in
    // flow — this maps directly onto the analytics `flow` label.
    context.read<AuthCubit>().verifyOtp(
          _code,
          flow: widget.otpId == null ? 'sign_up' : 'sign_in',
        );
  }

  void _clearCode() {
    _controller.clear();
    if (mounted) {
      _focusNode.requestFocus();
      setState(() {});
    }
  }

  void _onResend() {
    if (_secondsRemaining > 0) return;
    // Guard against a second tap while a request is already in flight.
    if (context.read<AuthCubit>().state is OtpResending) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().resendOtp(otpId: widget.otpId);
  }

  /// Leaving the screen abandons the pending verification (signup flow) so a
  /// later launch doesn't bring the user back here; routes to login when there
  /// is nothing to pop (e.g. opened from splash on relaunch).
  void _onBack() {
    final cubit = context.read<AuthCubit>();
    // Navigate first so leaving never waits on (or is blocked by) the cleanup.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
    if (widget.otpId == null) {
      unawaited(cubit.cancelOtpVerification());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is OtpVerified) {
            context.go('/home');
          } else if (state is OtpResent) {
            // Fresh code sent — restart the countdown and clear the old input.
            _clearCode();
            _startResendTimer();
            AppHelpers.showSnackBar(context, state.message);
          } else if (state is OtpResendFailure) {
            // Keep the entered code — the previous OTP may still be valid.
            AppHelpers.showSnackBar(context, state.message, isError: true);
          } else if (state is AuthError) {
            AppHelpers.showSnackBar(context, state.message, isError: true);
            _clearCode();
          }
        },
        builder: (context, state) {
          final isVerifying = state is OtpVerifying;
          final isResending = state is OtpResending;
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 24.w, top: 4.h, right: 24.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _onBack,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.arrow_back,
                        color: ui.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppUtils.horizontal24Padding.copyWith(top: 4.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: AppPngImageView(
                            appImagePath: ui.isLight
                                ? AppImages.hubcoLogoLight
                                : AppImages.hubcoLogo,
                            width: MediaQuery.sizeOf(context).width * 0.45,
                          ),
                        ),
                        24.verticalSpace,
                        AppText(
                          // The OTP target is an email when sign-up / login used one.
                          AppHelpers.isEmailInput(widget.phoneNumber)
                              ? 'Verify Your Email'
                              : 'Verify Your Number',
                          textAlign: TextAlign.center,
                          color: ui.textPrimary,
                          fontSize: FontSizes.font28Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        8.verticalSpace,
                        AppText(
                          'Enter the 6-digit code sent to',
                          textAlign: TextAlign.center,
                          color: ui.textMuted,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        4.verticalSpace,
                        AppText(
                          '${widget.countryCode} ${widget.phoneNumber}'.trim(),
                          textAlign: TextAlign.center,
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight600,
                        ),
                        32.verticalSpace,
                        _buildOtpInput(),
                        32.verticalSpace,
                        PrimaryButtonWidget(
                          text: 'Verify',
                          onPress: _onVerify,
                          isLoading: isVerifying,
                          buttonHeight: 38.h,
                          cornerRadius: 24.r,
                          gradientColors: const [
                            AppColors.primaryDarkColor,
                            AppColors.primaryDarkButtonColor,
                          ],
                          textColor: AppColors.whiteColor,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight600,
                        ),
                        24.verticalSpace,
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
                              onTap: (_secondsRemaining > 0 || isResending)
                                  ? null
                                  : _onResend,
                              child: AppText(
                                isResending
                                    ? 'Sending...'
                                    : _secondsRemaining > 0
                                        ? 'Resend in $_formattedRemaining'
                                        : 'Resend',
                                color: (_secondsRemaining > 0 || isResending)
                                    ? ui.textMuted
                                    : ui.brandPrimary,
                                fontSize: FontSizes.font12Sp,
                                fontWeight: FontWeights.weight600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Six display boxes with one invisible text field stretched over them, so
  /// a tap anywhere on the row focuses the field and opens the keyboard.
  Widget _buildOtpInput() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_kOtpLength, _buildOtpBox),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [OtpInputFormatter(_kOtpLength)],
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: _onChanged,
              // Keep the caret at the end so typing always fills the next box.
              onTap: () => _controller.selection =
                  TextSelection.collapsed(offset: _controller.text.length),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    final ui = AppUiColors.of(context);
    final code = _code;
    final bool filled = index < code.length;
    final int activeIndex =
        code.length < _kOtpLength ? code.length : _kOtpLength - 1;
    final bool active = _focusNode.hasFocus && index == activeIndex;
    return Container(
      width: 48.w,
      height: 56.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ui.inputFill,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (filled || active) ? ui.brandPrimary : ui.inputBorder,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Text(
        filled ? code[index] : '',
        style: TextStyle(
          color: ui.textPrimary,
          fontSize: FontSizes.font20Sp,
          fontWeight: FontWeights.weight700,
        ),
      ),
    );
  }
}
