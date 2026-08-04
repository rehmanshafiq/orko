import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs HTTP requests and responses for debugging.
///
/// SECURITY: this interceptor must only ever be added to the Dio chain in
/// debug builds (see [ApiClient]). As defence-in-depth every write goes through
/// [_log], which is a no-op outside debug builds, so no request/response data
/// (URLs, bodies, tokens) can ever reach the device log in release/profile
/// builds even if the interceptor is somehow added to the chain there. It also
/// redacts credentials/secrets from the fields it prints, so even a stray debug
/// log never emits a bearer token, password or OTP.
class LoggingInterceptor extends Interceptor {
  /// Writes [message] to the device log only in debug builds. In release and
  /// profile builds this is a no-op, so API requests/responses are never
  /// printed or logged.
  static void _log(String message) {
    if (kDebugMode) developer.log(message);
  }

  /// Header/body keys whose values must never be written to the log.
  static const Set<String> _sensitiveKeys = {
    'authorization',
    'password',
    'confirm_password',
    'new_password',
    'current_password',
    'otp',
    'token',
    'access',
    'refresh',
    'access_token',
    'refresh_token',
  };

  /// Returns a copy of [map] with sensitive values replaced by `***`,
  /// recursing into nested maps/lists so tokens buried in a response body
  /// (e.g. `body.access`) are redacted too.
  static Map<String, dynamic> _redact(Map map) {
    return map.map((key, value) {
      final isSensitive = _sensitiveKeys.contains(key.toString().toLowerCase());
      return MapEntry(key.toString(), isSensitive ? '***' : _redactValue(value));
    });
  }

  static Object? _redactValue(dynamic value) {
    if (value is Map) return _redact(value);
    if (value is List) return value.map(_redactValue).toList();
    return value;
  }

  /// Renders a request/response body for logging, redacting known secret
  /// fields when it is a JSON map. Non-map bodies (e.g. FormData) are only
  /// described by type so file/multipart contents are never dumped.
  static Object? _safeBody(dynamic data) {
    if (data is Map) return _redact(data);
    if (data == null) return null;
    return '<${data.runtimeType}>';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('┌──────────────────────────────────────────────');
    _log('│ REQUEST: ${options.method} ${options.uri}');
    _log('│ Headers: ${_redact(options.headers)}');
    if (options.data != null) {
      _log('│ Body: ${_safeBody(options.data)}');
    }
    _log('└──────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log('┌──────────────────────────────────────────────');
    _log('│ RESPONSE [${response.statusCode}]: ${response.requestOptions.uri}');
    _log('│ Data: ${_safeBody(response.data)}');
    _log('└──────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log('┌──────────────────────────────────────────────');
    _log('│ ERROR [${err.response?.statusCode}]: ${err.requestOptions.uri}');
    _log('│ Message: ${err.message}');
    if (err.response?.data != null) {
      _log('│ Response: ${_safeBody(err.response?.data)}');
    }
    _log('└──────────────────────────────────────────────');
    handler.next(err);
  }
}
