import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/api_constants.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
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

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      log('[Auth] Login URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'phone_number': phoneNumber,
          'country_code': countryCode,
          'password': password,
          // FCM device token so the backend can target push notifications.
          // Omitted when unavailable (e.g. permission denied / no Play Services).
          if (AppStorage.fcmToken.isNotEmpty) 'token': AppStorage.fcmToken,
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
  Future<SignUpResultModel> loginWithGoogle({
    required String name,
    required String email,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.loginWithGoogle;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Google sign-in is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      log('[Auth] Login-with-google URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'name': name,
          'email': email,
          if (AppStorage.fcmToken.isNotEmpty) 'token': AppStorage.fcmToken,
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
            : 'Google sign-in failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'Google sign-in failed'),
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
        ApiClient.baseUrl,
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

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
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

  @override
  Future<String> resendOtp({
    String? otpId,
    String? accessToken,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.resendOtp;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Resend OTP is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      log('[Auth] Resend-OTP URL: $url');

      final Response response;
      if (otpId != null && otpId.trim().isNotEmpty) {
        // Sign-in OTP flow — identify the pending OTP by id (no auth header).
        response = await apiClient.post(
          url,
          data: {'otp_id': int.tryParse(otpId.trim()) ?? otpId.trim()},
        );
      } else {
        // Signup verification flow — authorize with the saved JWT, no body.
        response = await apiClient.post(
          url,
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );
      }

      final data = response.data;
      final isOk = response.statusCode == 200 &&
          (data is! Map || data['status'] == null || data['status'] == 200);
      if (isOk) {
        if (data is Map) {
          final body = data['body'];
          if (body is Map && body['data'] != null) {
            return body['data'].toString();
          }
        }
        return 'A new code has been sent';
      }

      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Could not resend the code',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'Could not resend the code'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.getUser;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'User profile is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      log('[Auth] Get user URL: $url');

      final response = await apiClient.get(url);

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        // The user lives under `body.user`.
        final user = body is Map ? body['user'] : null;
        if (user is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(user));
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to load user',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'Failed to load user'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> editUserProfile(Map<String, dynamic> data) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.editUserProfile;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Editing your profile is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      log('[Auth] Edit-user-profile URL: $url');

      final response = await apiClient.patch(url, data: data);

      final responseData = response.data;
      final isOk = (response.statusCode == 200 || response.statusCode == 201) &&
          (responseData is! Map ||
              responseData['status'] == null ||
              responseData['status'] == 200 ||
              responseData['status'] == 201);
      if (isOk) return;

      throw ServerException(
        message: (responseData is Map && responseData['message'] != null)
            ? responseData['message'].toString()
            : 'Failed to update profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Failed to update profile'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> uploadUserPicture(String imagePath) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.uploadUserPicture;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Updating your photo is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      log('[Auth] Upload-user-picture URL: $url');

      final fileName = imagePath.split('/').last;
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'jpg';
      // Backend only accepts jpg/jpeg/png — tag the part with the right MIME
      // type so it isn't sent as application/octet-stream.
      final subtype = (ext == 'png')
          ? 'png'
          : (ext == 'jpeg')
              ? 'jpeg'
              : 'jpeg';
      final safeName = fileName.contains('.') ? fileName : '$fileName.jpg';

      // The backend reads the file from the `profile_img` field.
      final formData = FormData.fromMap({
        'profile_img': await MultipartFile.fromFile(
          imagePath,
          filename: safeName,
          contentType: DioMediaType('image', subtype),
        ),
      });

      // Pass the FormData straight through — do NOT set Content-Type manually.
      // Dio generates `multipart/form-data; boundary=…` itself; setting it by
      // hand drops the boundary and the server rejects the upload.
      final response = await apiClient.post(url, data: formData);

      final responseData = response.data;
      final isOk = (response.statusCode == 200 || response.statusCode == 201) &&
          (responseData is! Map ||
              responseData['status'] == null ||
              responseData['status'] == 200 ||
              responseData['status'] == 201);
      if (isOk) return;

      throw ServerException(
        message: (responseData is Map && responseData['message'] != null)
            ? responseData['message'].toString()
            : 'Failed to upload picture',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Failed to upload picture'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Extracts a human-readable message from a Dio error response.
  String _dioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
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
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.logoutApi;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Logout is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      log('[Auth] Logout URL: $url');

      final response = await apiClient.get(url);

      final data = response.data;
      final isOk = response.statusCode == 200 &&
          (data is! Map || data['status'] == null || data['status'] == 200);
      if (isOk) return;

      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Logout failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'Logout failed'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }
}
