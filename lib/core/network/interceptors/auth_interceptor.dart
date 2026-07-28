import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/secure_store.dart';

/// Intercepts requests to attach the auth token.
///
/// NOTE: the backend currently exposes no token-refresh endpoint. When a
/// refresh endpoint is added, insert a single-flight refresh here (retry the
/// original request on success). A 401 is passed through to the caller, which
/// handles it (e.g. by showing a Login Required dialog).
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
}
