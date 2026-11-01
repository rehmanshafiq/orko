import 'package:dio/dio.dart';
import 'package:orko_hubco/core/network/integrity/app_integrity_service.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Proves each Hubco API call comes from the genuine app on a genuine device:
/// attaches a Play Integrity token (Android) or an App Attest assertion (iOS)
/// to every request the backend checks (see [AppIntegrityService.appliesTo]).
///
/// When the backend rejects a request for integrity (HTTP 403 with one of the
/// exact [_reverifyMessage] / [_unverifiedMessage] exception texts — 403 alone
/// is not unique to integrity) it retries ONCE with a fresh proof, after
/// re-attesting on iOS when asked to. A second failure is passed on with the
/// backend's exception text as the user-facing `message`.
///
/// Must sit before [ErrorInterceptor] so a request that succeeds on retry is
/// never toasted as an error.
class IntegrityInterceptor extends Interceptor {
  IntegrityInterceptor(this._dio, {AppIntegrityService? service})
      : _service = service ?? AppIntegrityService.instance;

  final Dio _dio;
  final AppIntegrityService _service;

  /// `RequestOptions.extra` key marking the one integrity retry.
  static const String _retriedKey = 'integrityRetried';

  /// iOS: headers missing or key unknown to the backend.
  static const String _reverifyMessage =
      'This device needs to be verified again. Please restart the app.';

  /// Both platforms: proof present but rejected.
  static const String _unverifiedMessage =
      'This app could not be verified. Please install the official app from '
      'Google Play.';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // A retried request carries the previous (now spent) proof; drop it.
    options.headers.removeWhere(
      (key, _) => AppIntegrityService.headerNames
          .any((name) => name.toLowerCase() == key.toLowerCase()),
    );
    if (_service.appliesTo(options)) {
      try {
        options.headers.addAll(await _service.headersFor(options, _dio));
      } catch (e) {
        // Best-effort: the backend decides what an unproven request gets.
        AppLogger.d('[Integrity] could not attach proof: $e');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final exception = _integrityException(err.response);
    if (exception == null) return handler.next(err);

    final request = err.requestOptions;
    // A stream body was consumed by the first attempt and can't be resent.
    if (request.extra[_retriedKey] == true || request.data is Stream) {
      return handler.next(_withMessage(err, exception));
    }

    if (exception == _reverifyMessage) {
      final sentKeyId = request.headers[AppIntegrityService.attestKeyIdHeader];
      await _service.invalidateAttestation(sentKeyId?.toString());
    }

    final data = request.data;
    final retry = request.copyWith(
      // Multipart bodies are finalized once sent; resend a fresh copy.
      data: data is FormData ? data.clone() : data,
      extra: {...request.extra, _retriedKey: true},
    );
    try {
      // Re-runs the whole chain, so the retry gets a new token/assertion and
      // its own outcome is processed (toast, update flag) exactly once.
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      handler.reject(retryError);
    }
  }

  /// The backend's integrity exception text, or `null` for any other error.
  static String? _integrityException(Response<dynamic>? response) {
    if (response?.statusCode != 403) return null;
    final data = response!.data;
    final exception = data is Map ? data['exception'] : null;
    if (exception is! String) return null;
    final text = exception.trim();
    return text == _reverifyMessage || text == _unverifiedMessage ? text : null;
  }

  /// Surfaces the actionable exception text instead of the envelope's
  /// generic "Unauthorized" message.
  static DioException _withMessage(DioException err, String exception) {
    final response = err.response;
    final data = response?.data;
    if (response != null && data is Map) {
      response.data = {...Map<String, dynamic>.from(data), 'message': exception};
    }
    return err.copyWith(response: response, message: exception);
  }
}
