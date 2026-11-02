import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/otp_input_formatter.dart';

/// Row of digit boxes for the change-email / change-phone OTP. A single
/// invisible text field holds the whole code and the boxes only render it:
/// moving focus between per-digit fields makes iOS tear down and re-attach the
/// input connection, which bounces the keyboard on every key. Pasting or SMS
/// autofill of a full code fills every box.
///
/// Reports the code through [onChanged]; clear it via
/// `GlobalKey<OtpCodeFieldState>().currentState?.clear()`.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.onChanged,
    this.length = 6,
    super.key,
  });

  final int length;
  final ValueChanged<String> onChanged;

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  /// Empties every box and (optionally) focuses the field for re-entry.
  void clear({bool focus = true}) {
    _controller.clear();
    if (focus) _focusNode.requestFocus();
    _notify();
  }

  void _notify() {
    setState(() {});
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (i) => _buildBox(ui, i)),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [OtpInputFormatter(widget.length)],
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: (_) => _notify(),
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

  Widget _buildBox(AppUiColors ui, int index) {
    final code = _controller.text;
    final filled = index < code.length;
    final activeIndex =
        code.length < widget.length ? code.length : widget.length - 1;
    final active = _focusNode.hasFocus && index == activeIndex;
    return Container(
      width: 46.w,
      height: 54.h,
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

/// Tracks the code's expiry and the resend cooldown from wall-clock deadlines,
/// so the countdowns stay correct while the app is backgrounded.
class OtpRequestClock extends ChangeNotifier {
  OtpRequestClock({required this.validFor, required this.resendAfter});

  /// How long a sent code stays valid (backend: 2 minutes).
  final Duration validFor;

  /// Minimum gap between requests.
  final Duration resendAfter;

  DateTime? _expiresAt;
  DateTime? _resendAt;
  Timer? _ticker;

  /// A code was just sent: restart both countdowns.
  void codeSent() {
    final now = DateTime.now();
    _expiresAt = now.add(validFor);
    _resendAt = now.add(resendAfter);
    _tick();
  }

  /// The server refused a request as too soon: block requests for another
  /// [resendAfter] without touching the current code's expiry.
  void holdRequests() {
    _resendAt = DateTime.now().add(resendAfter);
    _tick();
  }

  /// The server reported the code as expired or cancelled.
  void expireCode() {
    _expiresAt = DateTime.now();
    _tick();
  }

  int get secondsUntilExpiry => _secondsUntil(_expiresAt);
  int get secondsUntilResend => _secondsUntil(_resendAt);
  bool get isExpired => _expiresAt != null && secondsUntilExpiry == 0;
  bool get canRequest => secondsUntilResend == 0;

  int _secondsUntil(DateTime? deadline) {
    if (deadline == null) return 0;
    final ms = deadline.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _tick() {
    notifyListeners();
    _ticker?.cancel();
    if (secondsUntilExpiry == 0 && secondsUntilResend == 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
      if (secondsUntilExpiry == 0 && secondsUntilResend == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// `m:ss` for a countdown in seconds.
String formatOtpCountdown(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// How a change-email/phone error should steer the flow. Matched loosely on
/// the backend `message` (case-insensitive) so small wording tweaks still work.
enum OtpErrorKind {
  /// "Invalid OTP" — retry with the same code request.
  invalidOtp,

  /// "OTP has expired…" — offer a new code.
  expired,

  /// "Too many incorrect attempts…" — the code is cancelled; back to step 1.
  tooManyAttempts,

  /// "…already registered with another account." — back to the input.
  alreadyRegistered,

  /// "Please wait a minute…" — request throttle (phone only).
  throttled,

  other;

  static OtpErrorKind of(String message) {
    final m = message.toLowerCase();
    if (m.contains('too many incorrect')) return tooManyAttempts;
    if (m.contains('already registered')) return alreadyRegistered;
    if (m.contains('expired')) return expired;
    if (m.contains('please wait')) return throttled;
    if (m.contains('invalid otp')) return invalidOtp;
    return other;
  }
}
