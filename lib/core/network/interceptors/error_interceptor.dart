import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Normalises every failed request into a clean, user-facing message, so each
/// datasource's error helper (which reads `response.data['message']`, falling
/// back to `DioException.message`) shows the same text for the same failure.
///
/// For an HTTP error response:
/// * a backend `message` is kept as-is;
/// * otherwise one is derived from common error shapes — `errors` (DRF field
///   errors, list or string), `detail`, `error`, or field errors under `body`;
/// * otherwise one [genericMessage] is used, whatever the status code.
///
/// The result is written to `response.data['message']` (other keys preserved)
/// and to [DioException.message]. Transport failures (timeouts, no network,
/// bad certificate) get a readable [DioException.message] too.
///
/// Every HTTP error status — and a `2xx` whose body carries an error `status`,
/// e.g. `{ "status": 401, "message": "..." }` — also reports its message via
/// [onErrorMessage] (a toast, wired at app start-up). A request can opt out
/// with `Options(extra: {ErrorInterceptor.silentKey: true})`.
///
/// Requests that accept a status via `validateStatus` (e.g. verify-QR's 422)
/// never reach [onError] and are not toasted.
class ErrorInterceptor extends Interceptor {
  /// Receives the user-facing message of every failed request. Kept as a hook
  /// so this network layer has no UI dependency (and stays unit-testable).
  static void Function(String message)? onErrorMessage;

  /// `RequestOptions.extra` key that suppresses [onErrorMessage] for a request.
  static const String silentKey = 'silentError';

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Some endpoints answer `200 OK` with the real error status in the body.
    final code = response.statusCode ?? 0;
    final data = response.data;
    if (code >= 200 && code < 300 && data is Map) {
      final bodyStatus = data['status'];
      if (bodyStatus is int && bodyStatus >= 400) {
        _report(
          response.requestOptions,
          _extractMessage(data) ?? genericMessage,
        );
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response == null) {
      handler.next(err.copyWith(message: _transportMessage(err)));
      return;
    }

    final code = response.statusCode;
    final data = response.data;
    final message = _extractMessage(data) ?? genericMessage;

    // Keep the original payload's other keys; only guarantee `message`.
    response.data = data is Map
        ? {...Map<String, dynamic>.from(data), 'message': message}
        : <String, dynamic>{'message': message};

    AppLogger.d(
      '[Network] ${err.requestOptions.method} ${err.requestOptions.path} '
      'failed ($code): $message',
    );
    _report(err.requestOptions, message);

    handler.next(err.copyWith(response: response, message: message));
  }

  static void _report(RequestOptions options, String message) {
    if (options.extra[silentKey] == true) return;
    onErrorMessage?.call(message);
  }

  /// Shown for any HTTP error status the backend didn't describe itself.
  static const String genericMessage =
      'Something went wrong. Please try again later.';

  /// Pulls a backend-provided message out of the common error payload shapes,
  /// or `null` when there is none.
  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final direct = _text(data['message']) ??
          _text(data['detail']) ??
          _firstError(data['errors']) ??
          _firstError(data['error']);
      if (direct != null) return direct;

      // Some endpoints nest DRF field errors under `body`, e.g.
      // {"body": {"email": ["Enter a valid email address."]}}.
      final body = data['body'];
      if (body is Map && body.isNotEmpty && body.values.first is List) {
        return _firstError(body);
      }
      return null;
    }

    // A short plain-text body is usually the message; HTML error pages
    // (proxies, gateways) are not.
    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty && text.length <= 200 && !text.startsWith('<')) {
        return text;
      }
    }
    return null;
  }

  /// First readable string from an errors value: a string, a list of strings,
  /// a map of field → string/list, or a map with its own `message`.
  static String? _firstError(dynamic errors) {
    if (errors is String) return _text(errors);
    if (errors is List && errors.isNotEmpty) return _firstError(errors.first);
    if (errors is Map && errors.isNotEmpty) {
      return _text(errors['message']) ?? _firstError(errors.values.first);
    }
    return null;
  }

  static String? _text(dynamic value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static String _transportMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Please check your internet connection '
            'and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Please check your internet '
            'connection and try again.';
      case DioExceptionType.badCertificate:
        return 'A secure connection could not be established. Please try '
            'again later.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          return 'Unable to reach the server. Please check your internet '
              'connection and try again.';
        }
        return err.message ?? genericMessage;
      case DioExceptionType.badResponse:
        return genericMessage;
    }
  }
}
