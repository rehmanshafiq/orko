import 'package:flutter/services.dart';
import 'package:orko_hubco/core/utils/helpers.dart';

/// Caps a "phone number or email" field: [maxEmailLength] characters while the
/// input reads as an email, [maxPhoneLength] while it reads as a phone number.
///
/// - Typing past the email cap is ignored. A pasted email longer than the cap
///   is kept whole (up to the RFC limit, [hardEmailLength]) instead of being
///   cut short into a different, possibly still valid, address — the validator
///   then asks the user to shorten it.
/// - A pasted international number (`+923123456789`, `00923123456789`, …) is
///   folded into `03XXXXXXXXX`; anything else past the phone cap is ignored.
class PhoneOrEmailInputFormatter extends TextInputFormatter {
  static const int maxEmailLength = 60;
  static const int hardEmailLength = 254;
  static const int maxPhoneLength = 11;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (AppHelpers.isEmailInput(text)) {
      if (text.length <= maxEmailLength) return newValue;
      final isPaste = text.length - oldValue.text.length > 1;
      return isPaste && text.length <= hardEmailLength ? newValue : oldValue;
    }
    if (text.length <= maxPhoneLength) return newValue;

    final normalized = AppHelpers.normalizePhoneOrEmail(text);
    if (RegExp(r'^03\d{9}$').hasMatch(normalized)) {
      return TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    return oldValue;
  }
}
