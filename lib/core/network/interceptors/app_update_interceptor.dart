import 'dart:convert';

import 'package:dio/dio.dart';

/// Reads the `update_available` flag the backend adds to every response
/// envelope — successes and errors alike — and reports it via
/// [onUpdateLevel]:
/// * `0` — the app is up to date;
/// * `1` — a newer version exists (soft update);
/// * `2` — this version is no longer supported (force update).
///
/// Missing, null, out-of-range or unparsable values are ignored. Numeric
/// strings (`"1"`) and whole doubles (`1.0`) are accepted.
///
/// Never alters or fails a request: it only observes the payload.
class AppUpdateInterceptor extends Interceptor {
  /// Receives every valid update level. Kept as a hook so this network layer
  /// has no UI dependency; wired at app start-up.
  static void Function(int level)? onUpdateLevel;

  /// Envelope key carrying the update level.
  static const String updateKey = 'update_available';

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _report(response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _report(err.response?.data);
    handler.next(err);
  }

  static void _report(dynamic data) {
    final level = parseLevel(data);
    if (level == null) return;
    try {
      onUpdateLevel?.call(level);
    } catch (_) {
      // Best-effort: update prompting must never break a request.
    }
  }

  /// The update level in a response body, or `null` when absent or invalid.
  static int? parseLevel(dynamic data) {
    final body = data is String ? _decode(data) : data;
    if (body is! Map) return null;

    final raw = body[updateKey];
    int? level;
    if (raw is int) {
      level = raw;
    } else if (raw is double && raw == raw.truncateToDouble()) {
      level = raw.toInt();
    } else if (raw is String) {
      level = int.tryParse(raw.trim());
    }
    if (level == null || level < 0 || level > 2) return null;
    return level;
  }

  /// A JSON object body Dio left undecoded (e.g. a wrong `Content-Type`).
  static dynamic _decode(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }
}
