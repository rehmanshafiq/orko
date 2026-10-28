import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/secure_store.dart';

/// Intercepts requests to attach the auth token, and forces a logout when the
/// backend rejects that token with a 401.
///
/// NOTE: the backend currently exposes no token-refresh endpoint. When a
/// refresh endpoint is added, insert a single-flight refresh in [onError]
/// (retry the original request on success) before falling back to
/// [onSessionExpired]. The 401 is still passed through to the caller.
class AuthInterceptor extends Interceptor {
  /// Ends the local session (clear tokens, route to login). Null for clients
  /// running outside the main UI engine (Android Auto, live-charging fetcher),
  /// which have no router and must not log the user out on their own.
  final Future<void> Function()? onSessionExpired;

  AuthInterceptor({this.onSessionExpired});

  /// Guards against concurrent 401s each triggering their own logout.
  bool _expiring = false;

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
    if (err.response?.statusCode == 401 && _sentCurrentToken(err.requestOptions)) {
      _expireSession();
    }
    handler.next(err);
  }

  /// Only a 401 on a request that carried the *current* token means the
  /// session is dead. This skips unauthenticated calls (e.g. a wrong-password
  /// login, guest browsing) and stale 401s for a token already replaced by a
  /// fresh login.
  bool _sentCurrentToken(RequestOptions options) {
    final token = SecureStore.instance.read(StorageConstants.accessToken);
    if (token == null || token.isEmpty) return false;
    return options.headers['Authorization'] == 'Bearer $token';
  }

  void _expireSession() {
    final callback = onSessionExpired;
    if (callback == null || _expiring) return;
    _expiring = true;
    callback().whenComplete(() => _expiring = false);
  }
}
