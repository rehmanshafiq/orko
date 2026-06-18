import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/api_constants.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/signup_result_model.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

/// Concrete implementation of [AuthRemoteDataSource] using Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  const AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SignUpResultModel> login({
    required String phoneNumber,
    required String countryCode,
    required String password,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.loginApi;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Login is not available right now',
        );
      }

      final url = _buildUrl(config.apiConstants.baseUrlQa, endpoint);
      log('[Auth] Login URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'phone_number': phoneNumber,
          'country_code': countryCode,
          'password': password,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is Map) {
          return SignUpResultModel.fromJson(Map<String, dynamic>.from(body));
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Login failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'Login failed'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        // Postman echo reflects our request data
        final echoedEmail = response.data['json']?['email']?.toString() ?? email;
        final echoedName = response.data['json']?['name']?.toString() ?? name;
        return UserModel(
          id: '1',
          email: echoedEmail,
          name: echoedName,
          avatarUrl: 'https://i.pravatar.cc/150?u=1',
        );
      }

      throw ServerException(
        message: response.data?['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<SignUpResultModel> completeSignup({
    required String name,
    required String phoneNumber,
    required String countryCode,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final url = _buildUrl(
        config.apiConstants.baseUrlQa,
        config.apiConstants.apiEndpoints.signUpForm,
      );

      log('[Auth] Complete-signup URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'country_code': countryCode,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is Map) {
          return SignUpResultModel.fromJson(Map<String, dynamic>.from(body));
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Sign up failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> verifyOtp({
    required String otp,
    required String accessToken,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.verifyOtp;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'OTP verification is not available right now',
        );
      }

      final url = _buildUrl(config.apiConstants.baseUrlQa, endpoint);
      log('[Auth] Verify-OTP URL: $url');

      final response = await apiClient.post(
        url,
        data: {'otp': otp},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      final data = response.data;
      final isOk = response.statusCode == 200 &&
          (data is! Map || data['status'] == null || data['status'] == 200);
      if (isOk) return;

      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'OTP verification failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'OTP verification failed'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Joins the base URL and endpoint path into a single clean URL.
  /// e.g. base + `api/v1/orko-auth/complete-signup`.
  String _buildUrl(String baseUrl, String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    var path = endpoint.trim();
    if (path.endsWith('?')) path = path.substring(0, path.length - 1);
    if (path.startsWith('/')) path = path.substring(1);
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    return '$base/$path';
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.logout);
    } catch (e) {
      throw ServerException(message: e.toString(), originalError: e);
    }
  }
}
