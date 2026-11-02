import 'package:flutter/services.dart';

/// Keeps an OTP field to at most [length] digits.
///
/// When a paste or SMS autofill inserts a whole code at once, the code
/// replaces whatever was already typed instead of being appended to it, and
/// it is extracted from surrounding text such as "Your code is 123456".
class OtpInputFormatter extends TextInputFormatter {
  OtpInputFormatter(this.length)
      : _fullCode = RegExp('(?<!\\d)\\d{$length}(?!\\d)');

  final int length;
  final RegExp _fullCode;

  static final RegExp _nonDigit = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final inserted = _insertedText(oldValue, newValue);
    String digits;
    if (inserted.length > 1 &&
        inserted.replaceAll(_nonDigit, '').length >= length) {
      // Prefer a standalone run of [length] digits; fall back to the first ones.
      digits = _fullCode.firstMatch(inserted)?.group(0) ??
          inserted.replaceAll(_nonDigit, '').substring(0, length);
    } else {
      digits = newValue.text.replaceAll(_nonDigit, '');
      if (digits.length > length) digits = digits.substring(0, length);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }

  /// Text added by this edit, worked out from the unchanged prefix and suffix
  /// around the old selection. Empty for deletions.
  static String _insertedText(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    final sel = oldValue.selection;
    final start =
        sel.isValid ? sel.start.clamp(0, oldText.length) : oldText.length;
    final end =
        sel.isValid ? sel.end.clamp(start, oldText.length) : oldText.length;
    final insertedEnd = newText.length - (oldText.length - end);
    if (insertedEnd <= start) return '';
    return newText.substring(start, insertedEnd);
  }
}
