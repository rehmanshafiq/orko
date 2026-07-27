import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/router/app_router.dart';
import 'package:orko_hubco/core/services/secure_store.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Intercepts requests to attach the auth token, and 401 responses to end the
/// session.
///
/// NOTE: the backend currently exposes no token-refresh endpoint, so a 401 is
/// treated as terminal — the session is cleared and the user is routed to
/// login. When a refresh endpoint is added, insert a single-flight refresh
/// here (retry the original request on success, fall through to logout on
/// failure).
class AuthInterceptor extends Interceptor {
  bool _loggingOut = false;

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
      _forceLogout();
    }
    handler.next(err);
  }

  /// Clears the encrypted session and routes to login. Guarded so a burst of
  /// concurrent 401s only tears down the session once.
  void _forceLogout() {
    if (_loggingOut) return;
    _loggingOut = true;
    // Best-effort: never let cleanup throw out of an error handler.
    Future(() async {
      try {
        await SecureStore.instance.clear();
        AuthRouterActions.onSessionExpired();
      } catch (e) {
        AppLogger.d('[Auth] forced-logout cleanup failed: $e', name: 'Auth');
      } finally {
        _loggingOut = false;
      }
    });
  }
}
