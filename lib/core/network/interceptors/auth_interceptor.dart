import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/secure_store.dart';

/// Intercepts requests to attach the auth token.
///
/// NOTE: the backend currently exposes no token-refresh endpoint. When a
/// refresh endpoint is added, insert a single-flight refresh here (retry the
/// original request on success). A 401 on an authenticated request of a real
/// (logged-in) session also triggers [onSessionExpired], which logs the user
/// out; the error is still passed through to the caller.
class AuthInterceptor extends Interceptor {
  /// Invoked when the server rejects the session token (401). Wired at app
  /// start-up so this network layer stays independent of routing/UI.
  static void Function()? onSessionExpired;

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
    final sentToken =
        err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && sentToken) {
      onSessionExpired?.call();
    }
    handler.next(err);
  }
}
