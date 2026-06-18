import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Attaches the platform/app headers the backend requires on every request:
/// `X-App-Version`, `X-Device-Type`, `X-Package-Name`.
///
/// Package info is resolved once and cached for the process lifetime. Header
/// resolution is best-effort — it never blocks or fails a request.
class AppHeadersInterceptor extends Interceptor {
  static String? _appVersion;
  static String? _packageName;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (_appVersion == null || _packageName == null) {
        final info = await PackageInfo.fromPlatform();
        _appVersion = info.version;
        _packageName = info.packageName;
      }
      options.headers['X-App-Version'] = _appVersion ?? '';
      options.headers['X-Package-Name'] = _packageName ?? '';
      options.headers['X-Device-Type'] = _deviceType;
    } catch (_) {
      // Best-effort headers — proceed regardless.
    }
    handler.next(options);
  }

  String get _deviceType {
    try {
      if (Platform.isIOS) return 'ios';
    } catch (_) {
      // Platform may be unavailable (e.g. tests) — default below.
    }
    return 'android';
  }
}
