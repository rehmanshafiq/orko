import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/usecases/request_email_change_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/verify_email_change_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/contact_change_widgets.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/otp_code_field.dart';

/// Two-step email-change flow:
///   1. Enter the new email → `change_email` sends an OTP to it.
///   2. Enter the OTP → `change_email_verify` updates the email.
///
/// The code is valid for 2 minutes, a new request cancels the previous code,
/// and 5 wrong tries cancel it. Pops the refreshed [UserEntity] on success
/// (the cached user is already updated by the verify call).
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({required this.currentEmail, super.key});

  final String currentEmail;

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

enum _Phase { enterEmail, enterOtp }

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFieldKey = GlobalKey<OtpCodeFieldState>();
  final TextEditingController _emailController = TextEditingController();

  /// The backend has no resend throttle for email; the short client cooldown
  /// only guards against accidental repeat taps.
  final OtpRequestClock _clock = OtpRequestClock(
    validFor: const Duration(minutes: 2),
    resendAfter: const Duration(seconds: 30),
  );

  _Phase _phase = _Phase.enterEmail;
  bool _busy = false;
  String _submittedEmail = '';
  String _code = '';

  /// Server-side rejection shown under the email field (e.g. already taken).
  String? _emailError;

  bool get _isCodeComplete => _code.length == kContactOtpLength;

  @override
  void dispose() {
    _clock.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Step 1: request the OTP ────────────────────────────────────────────────

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    setState(() => _emailError = null);
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    // The backend trims and lowercases too; match it so the OTP step shows
    // exactly the address being verified.
    await _sendCode(_emailController.text.trim().toLowerCase());
  }

  Future<void> _resendCode() async {
    if (!_clock.canRequest || _busy) return;
    await _sendCode(_submittedEmail);
  }

  /// Requests a code for [email]. Any earlier code stops working.
  Future<void> _sendCode(String email) async {
    if (_busy) return;
    setState(() => _busy = true);

    final result = await sl<RequestEmailChangeUseCase>()(
      RequestEmailChangeParams(email: email),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (failure) {
        AppHelpers.showSnackBar(context, failure.message, isError: true);
        // 422s ("already registered", "must be different") belong to the
        // email itself — show them under the field.
        if (failure.statusCode == 422) _backToEmail(error: failure.message);
      },
      (_) {
        final resent = _phase == _Phase.enterOtp;
        _clock.codeSent();
        _codeFieldKey.currentState?.clear();
        setState(() {
          _submittedEmail = email;
          _code = '';
          _phase = _Phase.enterOtp;
        });
        AppHelpers.showSnackBar(
          context,
          resent ? 'A new code was sent to $email.' : 'We sent a code to $email.',
        );
      },
    );
  }

  // ── Step 2: verify the OTP ─────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    if (_busy) return;
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
        'This code has expired. Send a new code to continue.',
        isError: true,
      );
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
      _onVerifyFailed,
      (user) {
        AppHelpers.showSnackBar(context, 'Your email has been updated.');
        Navigator.of(context).pop(user);
      },
    );
  }

  void _onVerifyFailed(Failure failure) {
    AppHelpers.showSnackBar(context, failure.message, isError: true);
    switch (OtpErrorKind.of(failure.message)) {
      case OtpErrorKind.tooManyAttempts:
        // The code is cancelled — a new one must be requested.
        _backToEmail();
      case OtpErrorKind.alreadyRegistered:
        // Someone else took the email meanwhile — pick another.
        _backToEmail(error: failure.message);
      case OtpErrorKind.expired:
        _clock.expireCode();
        _clearCode();
      case OtpErrorKind.invalidOtp:
      case OtpErrorKind.throttled:
      case OtpErrorKind.other:
        // "Invalid OTP" also covers expired codes for email: retry or resend.
        _clearCode();
    }
  }

  void _clearCode() {
    _codeFieldKey.currentState?.clear();
    setState(() => _code = '');
  }

  /// Returns to the email input, keeping what was typed. The clock keeps
  /// running so a quick re-send still respects the cooldown.
  void _backToEmail({String? error}) {
    setState(() {
      _code = '';
      _phase = _Phase.enterEmail;
      _emailError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return PopScope(
      // From the OTP step, back (app bar or system) returns to the email step.
      canPop: _phase == _Phase.enterEmail && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _busy) return;
        _backToEmail();
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
                  : OtpStepView(
                      target: _submittedEmail,
                      codeFieldKey: _codeFieldKey,
                      onCodeChanged: (code) => setState(() => _code = code),
                      codeComplete: _isCodeComplete,
                      busy: _busy,
                      clock: _clock,
                      onVerify: _verifyCode,
                      onResend: _resendCode,
                      changeTargetLabel: 'Use a different email',
                      onChangeTarget: _backToEmail,
                    ),
            ),
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
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            onFieldSubmitted: (_) => _requestCode(),
            validator: _validateNewEmail,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
              fontFamily: AppFonts.lexend,
            ),
            cursorColor: ui.brandPrimary,
            decoration: contactFieldDecoration(
              ui,
              hint: 'new@example.com',
              errorText: _emailError,
            ),
          ),
          28.verticalSpace,
          ContactChangeButton(
            label: _busy ? 'Sending…' : 'Send Verification Code',
            enabled: !_busy,
            onPress: _requestCode,
          ),
          24.verticalSpace,
        ],
      ),
    );
  }

  String? _validateNewEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    if (value.toLowerCase() == widget.currentEmail.trim().toLowerCase()) {
      return 'New email must be different from your current email.';
    }
    return null;
  }
}
