import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/usecases/request_phone_change_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/verify_phone_change_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/contact_change_widgets.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/otp_code_field.dart';

/// Two-step phone-change flow:
///   1. Enter the new number → `change_phone` sends an OTP and returns its
///      `otp_id`.
///   2. Enter the OTP → `change_phone_verify` (`otp_id` + `otp`) updates it.
///
/// The code is valid for 2 minutes, 5 wrong tries cancel it, and requests are
/// throttled to one per 60 seconds. Pops the refreshed [UserEntity] on success
/// (the cached user is already updated by the verify call).
class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({
    required this.currentPhone,
    required this.countryCode,
    super.key,
  });

  /// Current local number (without the dial code); may be empty.
  final String currentPhone;

  /// Dial code sent with the new number, e.g. `+92`.
  final String countryCode;

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

enum _Phase { enterPhone, enterOtp }

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  static const int _minDigits = 7;
  static const int _maxDigits = 15;

  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFieldKey = GlobalKey<OtpCodeFieldState>();
  final TextEditingController _phoneController = TextEditingController();

  /// Mirrors the backend: 2-minute code, one request per 60 seconds.
  final OtpRequestClock _clock = OtpRequestClock(
    validFor: const Duration(minutes: 2),
    resendAfter: const Duration(seconds: 60),
  );

  _Phase _phase = _Phase.enterPhone;
  bool _busy = false;
  String _submittedPhone = '';
  String _code = '';

  /// Id of the latest code; verify needs it. Cleared when the code is
  /// cancelled.
  int? _otpId;

  /// Server-side rejection shown under the phone field (e.g. already taken).
  String? _phoneError;

  bool get _isCodeComplete => _code.length == kContactOtpLength;

  @override
  void dispose() {
    _clock.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Digits only, without leading zeros — `03119998887` and `3119998887` are
  /// the same number to the backend.
  static String _normalize(String value) =>
      value.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');

  // ── Step 1: request the OTP ────────────────────────────────────────────────

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    setState(() => _phoneError = null);
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    await _sendCode(_phoneController.text.trim());
  }

  Future<void> _resendCode() => _sendCode(_submittedPhone);

  /// Requests a code for [phone]. Any earlier code stops working.
  Future<void> _sendCode(String phone) async {
    if (_busy) return;
    if (!_clock.canRequest) {
      AppHelpers.showSnackBar(
        context,
        'Please wait ${formatOtpCountdown(_clock.secondsUntilResend)} before '
        'requesting a new code.',
        isError: true,
      );
      return;
    }
    setState(() => _busy = true);

    final result = await sl<RequestPhoneChangeUseCase>()(
      RequestPhoneChangeParams(
        phoneNumber: phone,
        countryCode: widget.countryCode,
      ),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) {
        AppHelpers.showSnackBar(context, failure.message, isError: true);
        if (OtpErrorKind.of(failure.message) == OtpErrorKind.throttled) {
          // Sent too soon (e.g. from another device) — wait out the throttle.
          _clock.holdRequests();
        } else if (failure.statusCode == 422) {
          // Invalid / unchanged / already registered — about the number.
          _backToPhone(error: failure.message);
        }
      },
      (otpId) {
        final resent = _phase == _Phase.enterOtp;
        _clock.codeSent();
        _codeFieldKey.currentState?.clear();
        setState(() {
          _otpId = otpId;
          _submittedPhone = phone;
          _code = '';
          _phase = _Phase.enterOtp;
        });
        AppHelpers.showSnackBar(
          context,
          resent
              ? 'A new code was sent to $_displayPhone.'
              : 'We sent a code to $_displayPhone.',
        );
      },
    );
  }

  String get _displayPhone =>
      '${widget.countryCode} ${_normalize(_submittedPhone)}';

  // ── Step 2: verify the OTP ─────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    if (_busy) return;
    final otpId = _otpId;
    if (otpId == null) {
      // No live code (cancelled) — a new one must be requested.
      _backToPhone();
      return;
    }
    if (!_isCodeComplete) {
      AppHelpers.showSnackBar(
        context,
        'Please enter the $kContactOtpLength-digit code',
        isError: true,
      );
      return;
    }
    if (_clock.isExpired) {
      AppHelpers.showSnackBar(
        context,
        'OTP has expired. Please request a new one.',
        isError: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final result = await sl<VerifyPhoneChangeUseCase>()(
      VerifyPhoneChangeParams(otpId: otpId, otp: _code),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      _onVerifyFailed,
      (user) {
        AppHelpers.showSnackBar(context, 'Your phone number has been updated.');
        Navigator.of(context).pop(user);
      },
    );
  }

  void _onVerifyFailed(Failure failure) {
    AppHelpers.showSnackBar(context, failure.message, isError: true);
    switch (OtpErrorKind.of(failure.message)) {
      case OtpErrorKind.tooManyAttempts:
        // The code is cancelled — request a new one from step 1.
        _otpId = null;
        _backToPhone();
      case OtpErrorKind.alreadyRegistered:
        // Someone else took the number meanwhile — pick another.
        _otpId = null;
        _backToPhone(error: failure.message);
      case OtpErrorKind.expired:
        // Offer "Send new code" (2 minutes have passed, so the throttle has).
        _clock.expireCode();
        _clearCode();
      case OtpErrorKind.invalidOtp:
      case OtpErrorKind.throttled:
      case OtpErrorKind.other:
        _clearCode();
    }
  }

  void _clearCode() {
    _codeFieldKey.currentState?.clear();
    setState(() => _code = '');
  }

  /// Returns to the number input, keeping what was typed. The clock keeps
  /// running so the 60-second throttle still applies.
  void _backToPhone({String? error}) {
    setState(() {
      _code = '';
      _phase = _Phase.enterPhone;
      _phoneError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return PopScope(
      // From the OTP step, back (app bar or system) returns to the phone step.
      canPop: _phase == _Phase.enterPhone && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _busy) return;
        _backToPhone();
      },
      child: Scaffold(
        backgroundColor: ui.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: ui.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: ui.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: AppText(
            'Change Phone Number',
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
              child: _phase == _Phase.enterPhone
                  ? _buildPhoneStep(ui)
                  : OtpStepView(
                      target: _displayPhone,
                      codeFieldKey: _codeFieldKey,
                      onCodeChanged: (code) => setState(() => _code = code),
                      codeComplete: _isCodeComplete,
                      busy: _busy,
                      clock: _clock,
                      onVerify: _verifyCode,
                      onResend: _resendCode,
                      changeTargetLabel: 'Use a different number',
                      onChangeTarget: _backToPhone,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(AppUiColors ui) {
    return ListenableBuilder(
      listenable: _clock,
      builder: (context, _) {
        final waiting = !_clock.canRequest;
        return Form(
          key: _phoneFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              20.verticalSpace,
              AppText(
                'Enter your new phone number. We\'ll send a verification code '
                'to confirm it\'s yours.',
                color: ui.textSecondary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight400,
              ),
              20.verticalSpace,
              AppText(
                'New Phone Number',
                color: ui.textPrimary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
              6.verticalSpace,
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxDigits),
                ],
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                onFieldSubmitted: (_) => _requestCode(),
                validator: _validateNewPhone,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight500,
                  fontFamily: AppFonts.lexend,
                ),
                cursorColor: ui.brandPrimary,
                decoration: contactFieldDecoration(
                  ui,
                  hint: '3001234567',
                  prefixText: '${widget.countryCode} ',
                  errorText: _phoneError,
                ),
              ),
              28.verticalSpace,
              ContactChangeButton(
                label: _busy
                    ? 'Sending…'
                    : waiting
                        ? 'Send code in '
                            '${formatOtpCountdown(_clock.secondsUntilResend)}'
                        : 'Send Verification Code',
                enabled: !_busy && !waiting,
                onPress: _requestCode,
              ),
              24.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  String? _validateNewPhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length < _minDigits || digits.length > _maxDigits) {
      return 'Phone Number is invalid.';
    }
    final current = _normalize(widget.currentPhone);
    if (current.isNotEmpty && _normalize(digits) == current) {
      return 'New phone number must be different from your current phone number.';
    }
    return null;
  }
}
