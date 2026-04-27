import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';

/// Intercepts requests to attach the auth token.
/// Intercepts 401 responses to trigger re-authentication.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final box = GetStorage();
    final token = box.read<String>(StorageConstants.accessToken);

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
