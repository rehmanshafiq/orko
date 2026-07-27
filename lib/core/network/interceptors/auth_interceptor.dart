import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/secure_store.dart';

/// Intercepts requests to attach the auth token.
/// Intercepts 401 responses to trigger re-authentication.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Token is held encrypted at rest; read the in-memory mirror synchronously.
    final token = SecureStore.instance.read(StorageConstants.accessToken);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: Implement token refresh or force logout logic
    }
    handler.next(err);
  }
}
