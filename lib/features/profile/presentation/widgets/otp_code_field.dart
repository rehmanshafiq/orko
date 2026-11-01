import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';

/// Row of single-digit boxes for the change-email / change-phone OTP. Handles
/// auto-advance, backspace to the previous box and pasting a whole code.
///
/// Reports the joined code through [onChanged]; clear it via
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
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes =
      List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  /// Empties every box and (optionally) focuses the first one for re-entry.
  void clear({bool focus = true}) {
    for (final c in _controllers) {
      c.clear();
    }
    if (focus) _focusNodes.first.requestFocus();
    _notify();
  }

  void _notify() {
    setState(() {});
    widget.onChanged(_code);
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _distribute(value);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _notify();
  }

  void _distribute(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final lastIndex =
        (digits.length >= widget.length ? widget.length : digits.length) - 1;
    if (lastIndex >= 0) {
      _focusNodes[lastIndex.clamp(0, widget.length - 1)].requestFocus();
    }
    _notify();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _notify();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) => _buildBox(ui, i)),
    );
  }

  Widget _buildBox(AppUiColors ui, int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 46.w,
      height: 54.h,
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
