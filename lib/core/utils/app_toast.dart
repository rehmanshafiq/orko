import 'package:fluttertoast/fluttertoast.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

/// Context-free toasts, usable from outside the widget tree (e.g. the network
/// layer).
class AppToast {
  AppToast._();

  /// Identical messages within this window are shown once, so a burst of
  /// failing requests (parallel calls, polling) doesn't stack toasts.
  static const Duration _dedupeWindow = Duration(seconds: 3);

  static String? _lastMessage;
  static DateTime? _lastShownAt;

  /// Shows [message] as a red error toast.
  static void error(String message) {
    final text = message.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (text == _lastMessage &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _dedupeWindow) {
      return;
    }
    _lastMessage = text;
    _lastShownAt = now;

    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.removeColor,
      textColor: AppColors.whiteColor,
    );
  }
}
