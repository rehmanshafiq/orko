import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
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

  const VerifyOtpScreen({
    super.key,
    required this.phoneNumber,
    this.countryCode = '+92',
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(_kOtpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_kOtpLength, (_) => FocusNode());

  static const int _resendSeconds = 30;
  int _secondsRemaining = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isComplete => _code.length == _kOtpLength;

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

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste of full code into a single box.
      _distribute(value);
      return;
    }
    if (value.isNotEmpty && index < _kOtpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _distribute(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _kOtpLength; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final lastIndex =
        (digits.length >= _kOtpLength ? _kOtpLength : digits.length) - 1;
    if (lastIndex >= 0) {
      _focusNodes[lastIndex.clamp(0, _kOtpLength - 1)].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
    context.read<AuthCubit>().verifyOtp(_code);
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) {
      _focusNodes.first.requestFocus();
      setState(() {});
    }
  }

  void _onResend() {
    if (_secondsRemaining > 0) return;
    _clearCode();
    _startResendTimer();
    AppHelpers.showSnackBar(context, 'A new code has been sent');
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
          } else if (state is AuthError) {
            AppHelpers.showSnackBar(context, state.message, isError: true);
            _clearCode();
          }
        },
        builder: (context, state) {
          final isVerifying = state is OtpVerifying;
          return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 24.w, top: 4.h, right: 24.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
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
                      'Verify Your Number',
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
                      '${widget.countryCode} ${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                    32.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_kOtpLength, _buildOtpBox),
                    ),
                    32.verticalSpace,
                    PrimaryButtonWidget(
                      text: isVerifying ? 'Verifying...' : 'Verify',
                      onPress: _onVerify,
                      isEnabled: _isComplete && !isVerifying,
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
                          onTap: _onResend,
                          child: AppText(
                            _secondsRemaining > 0
                                ? 'Resend in ${_secondsRemaining}s'
                                : 'Resend',
                            color: _secondsRemaining > 0
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

  Widget _buildOtpBox(int index) {
    final ui = AppUiColors.of(context);
    final bool filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 48.w,
      height: 56.h,
      child: Focus(
        onKeyEvent: (_, event) => _onKey(index, event),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => _onChanged(index, value),
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
}
