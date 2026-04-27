import 'dart:developer';

import 'package:dio/dio.dart';

/// Logs all HTTP requests and responses for debugging.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('┌──────────────────────────────────────────────');
    log('│ REQUEST: ${options.method} ${options.uri}');
    log('│ Headers: ${options.headers}');
    if (options.data != null) {
      log('│ Body: ${options.data}');
    }
    log('└──────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('┌──────────────────────────────────────────────');
    log('│ RESPONSE [${response.statusCode}]: ${response.requestOptions.uri}');
    log('│ Data: ${response.data}');
    log('└──────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('┌──────────────────────────────────────────────');
    log('│ ERROR [${err.response?.statusCode}]: ${err.requestOptions.uri}');
    log('│ Message: ${err.message}');
    log('└──────────────────────────────────────────────');
    handler.next(err);
  }
}
