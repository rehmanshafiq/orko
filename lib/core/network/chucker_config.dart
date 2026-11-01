import 'dart:io' show Platform;

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Chucker Flutter — in-app HTTP inspector, enabled on Android debug builds
/// only. Every [ApiClient] request then shows an in-app notification whose
/// "Details" button opens the request/response log.
///
/// Callers guard with `kDebugMode && ChuckerConfig.enabled` so the compile-time
/// `kDebugMode` lets release builds tree-shake the Chucker code paths.
class ChuckerConfig {
  ChuckerConfig._();

  static final bool enabled = kDebugMode && !kIsWeb && Platform.isAndroid;

  /// Root navigator key for the app router. Chucker opens its screens through
  /// [ChuckerFlutter.navigatorKey], so it becomes the root key when enabled.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      kDebugMode && enabled
          ? ChuckerFlutter.navigatorKey
          : GlobalKey<NavigatorState>();
}
