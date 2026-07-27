import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Debug-only logger.
///
/// In release and profile builds every call is a no-op, so no diagnostic data
/// (request URLs, identifiers, coordinates, tokens or other PII) can reach the
/// device log (logcat / oslog). Use this instead of `dart:developer`'s `log`
/// or `print` for anything that might touch user data.
class AppLogger {
  const AppLogger._();

  /// Logs [message] only in debug builds.
  static void d(String message, {String name = 'app'}) {
    if (kDebugMode) developer.log(message, name: name);
  }
}
