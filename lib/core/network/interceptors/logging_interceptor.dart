import 'dart:developer';

import 'package:dio/dio.dart';

/// Logs HTTP requests and responses for debugging.
///
/// SECURITY: this interceptor must only ever be added to the Dio chain in
/// debug builds (see [ApiClient]). As a defence-in-depth second layer it also
/// redacts credentials/secrets from the fields it prints, so even if it is
/// somehow reached outside debug it never emits a bearer token, password or
/// OTP to the device log.
class LoggingInterceptor extends Interceptor {
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
    log('┌──────────────────────────────────────────────');
    log('│ REQUEST: ${options.method} ${options.uri}');
    log('│ Headers: ${_redact(options.headers)}');
    if (options.data != null) {
      log('│ Body: ${_safeBody(options.data)}');
    }
    log('└──────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('┌──────────────────────────────────────────────');
    log('│ RESPONSE [${response.statusCode}]: ${response.requestOptions.uri}');
    log('│ Data: ${_safeBody(response.data)}');
    log('└──────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('┌──────────────────────────────────────────────');
    log('│ ERROR [${err.response?.statusCode}]: ${err.requestOptions.uri}');
    log('│ Message: ${err.message}');
    if (err.response?.data != null) {
      log('│ Response: ${_safeBody(err.response?.data)}');
    }
    log('└──────────────────────────────────────────────');
    handler.next(err);
  }
}
