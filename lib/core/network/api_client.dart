import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orko_hubco/core/constants/api_constants.dart';
import 'package:orko_hubco/core/network/certificate_pinning.dart';
import 'package:orko_hubco/core/network/interceptors/app_headers_interceptor.dart';
import 'package:orko_hubco/core/network/interceptors/auth_interceptor.dart';
import 'package:orko_hubco/core/network/interceptors/logging_interceptor.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

/// Centralized API client wrapping Dio.
/// All features use this for HTTP communication.
class ApiClient {
  late final Dio _dio;

  Dio get dio => _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        // Resolved from Remote Config (falls back to ApiConstants.baseUrl until
        // config loads). See the [baseUrl] getter below.
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        // NOTE: `Content-Type` is intentionally NOT set globally. Setting it
        // here forces `application/json` on every request and clobbers the
        // `multipart/form-data; boundary=…` header Dio generates for FormData
        // uploads (the boundary goes missing and the server can't parse the
        // file). Content type is applied per-request below instead.
        headers: {
          'Accept': 'application/json',
          'Domain': _resolveDomain(),
        },
      ),
    );

    // Enforce TLS certificate pinning on API traffic (no-op in debug builds).
    final pinnedAdapter = CertificatePinning.adapter();
    if (pinnedAdapter != null) _dio.httpClientAdapter = pinnedAdapter;

    _dio.interceptors.addAll([
      AppHeadersInterceptor(),
      AuthInterceptor(),
      // SECURITY: verbose request/response logging is debug-only. It must never
      // ship in release/profile builds, where it would leak bearer tokens,
      // passwords and OTPs to the device log (logcat/oslog).
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  /// Single source of truth for the API host used by every feature datasource.
  ///
  /// Datasources should build their URLs against this instead of reading
  /// `config.apiConstants.baseUrlQa` directly — switching the whole app between
  /// environments is then a one-line change here:
  ///   * QA   → `config.apiConstants.baseUrlQa`
  ///   * Live → `config.apiConstants.baseUrlLive`
  ///
  /// Falls back to [ApiConstants.baseUrl] before Remote Config has resolved.
  static String get baseUrl {
    final config = RemoteConfigService.config;
    final resolved = config?.apiConstants.baseUrlLive;
    return (resolved == null || resolved.trim().isEmpty)
        ? ApiConstants.baseUrl
        : resolved;
  }

  /// Domain header value from Remote Config, defaulting to `Hubco` when the
  /// config hasn't resolved or doesn't provide one.
  static String _resolveDomain() {
    final domain = RemoteConfigService.config?.apiConstants.domain;
    return (domain == null || domain.trim().isEmpty) ? 'Hubco' : domain;
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _withContentType(options, data),
    );
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _withContentType(options, data),
    );
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _withContentType(options, data),
    );
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _withContentType(options, data),
    );
  }

  /// Applies the right `Content-Type` per request:
  /// * `FormData` → left untouched so Dio sets `multipart/form-data` WITH the
  ///   required `boundary` automatically.
  /// * everything else → defaults to `application/json` (unless the caller
  ///   already specified a content type).
  Options _withContentType(Options? options, dynamic data) {
    if (data is FormData) return options ?? Options();
    final opts = options ?? Options();
    if (opts.contentType != null) return opts;
    return opts.copyWith(contentType: Headers.jsonContentType);
  }
}
