import 'dart:io';

import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/core/network/interceptors/error_interceptor.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/signup_result_model.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

/// Concrete implementation of [AuthRemoteDataSource] using Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  const AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SignUpResultModel> login({
    required String phoneNumberEmail,
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
      AppLogger.d('[Auth] Login URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'phone_number_email': phoneNumberEmail,
          'country_code': countryCode,
          'password': password,
          // FCM device token so the backend can target push notifications.
          // Omitted when unavailable (e.g. permission denied / no Play Services).
          if (AppStorage.fcmToken.isNotEmpty) 'token': AppStorage.fcmToken,
        },
        // The login screen shows the failure itself; skip the global toast so
        // the message isn't shown twice.
        options: Options(extra: {ErrorInterceptor.silentKey: true}),
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
      throw ServerException(
        message: _dioMessage(e, fallback: 'Login failed'),
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
    required String token,
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
      AppLogger.d('[Auth] Login-with-google URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'name': name,
          'email': email,
          // Firebase ID token (from Google / Apple), verified by the backend.
          'token': token,
        },
        // The login screen shows the failure itself; skip the global toast so
        // the message isn't shown twice.
        options: Options(extra: {ErrorInterceptor.silentKey: true}),
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
      throw ServerException(
        message: _dioMessage(e, fallback: 'Google sign-in failed'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }


  @override
  Future<SignUpResultModel> completeSignup({
    required String name,
    required String phoneNumberEmail,
    required String countryCode,
    String? email,
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

      AppLogger.d('[Auth] Complete-signup URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'name': name,
          'phone_number_email': phoneNumberEmail,
          'country_code': countryCode,
          if (email != null && email.isNotEmpty) 'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
        // The register screen shows the failure itself; skip the global toast
        // so the message isn't shown twice.
        options: Options(extra: {ErrorInterceptor.silentKey: true}),
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
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Sign up failed'),
        statusCode: e.response?.statusCode,
        originalError: e,
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
      AppLogger.d('[Auth] Verify-OTP URL: $url');

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
      throw ServerException(
        message: _dioMessage(e, fallback: 'OTP verification failed'),
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
      AppLogger.d('[Auth] Resend-OTP URL: $url');

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
      throw ServerException(
        message: _dioMessage(e, fallback: 'Could not resend the code'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<int> loginWithOtp({
    required String phoneNumberEmail,
    required String countryCode,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.loginWithOtp;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Password reset is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      AppLogger.d('[Auth] Login-with-OTP URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'phone_number_email': phoneNumberEmail,
          'country_code': countryCode,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        final otpId = body is Map ? body['otp_id'] : null;
        final parsed = otpId is num
            ? otpId.toInt()
            : int.tryParse(otpId?.toString() ?? '');
        if (parsed != null) return parsed;
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Could not send the reset code',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Could not send the reset code'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<String> verifyResetOtp({
    required int otpId,
    required String otp,
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
      AppLogger.d('[Auth] Verify-reset-OTP URL: $url');

      // No Authorization header — the OTP itself authorizes this call.
      final response = await apiClient.post(
        url,
        data: {'otp_id': otpId, 'otp': otp},
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        final access = body is Map ? body['access'] : null;
        if (access is String && access.trim().isNotEmpty) return access;
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'OTP verification failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'OTP verification failed'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<String> resetPassword({
    required String accessToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.resetPassword;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Password reset is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      AppLogger.d('[Auth] Reset-password URL: $url');

      // Authorized with the short-lived token returned by verify-otp.
      final response = await apiClient.post(
        url,
        data: {
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      final data = response.data;
      final isOk = response.statusCode == 200 &&
          (data is! Map || data['status'] == null || data['status'] == 200);
      if (isOk) {
        return (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Password reset successfully.';
      }

      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Could not reset your password',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Could not reset your password'),
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
      AppLogger.d('[Auth] Get user URL: $url');

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
      throw ServerException(
        message: _dioMessage(e, fallback: 'Failed to load user'),
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
      AppLogger.d('[Auth] Edit-user-profile URL: $url');

      final response = await apiClient.patch(
        url,
        data: data,
        // The edit-profile screen shows the failure itself; skip the global
        // toast so the message isn't shown twice.
        options: Options(extra: {ErrorInterceptor.silentKey: true}),
      );

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
  Future<int> requestEmailChange({required String email}) async {
    final body = await _postContactChange(
      tag: 'Change-email',
      endpoint: (e) => e.changeEmail,
      unavailableMessage: 'Changing your email is not available right now',
      data: {'email': email.trim().toLowerCase()},
      fallback: 'Could not send the verification code',
    );
    // Email verify doesn't need the id; a 200 means the code was sent.
    return _otpIdOf(body) ?? 0;
  }

  @override
  Future<UserModel> verifyEmailChange({required String otp}) async {
    final body = await _postContactChange(
      tag: 'Change-email-verify',
      endpoint: (e) => e.changeEmailVerify,
      unavailableMessage: 'Changing your email is not available right now',
      data: {'otp': otp},
      fallback: 'Could not verify the code',
    );
    return _userOf(body, fallback: 'Could not verify the code');
  }

  @override
  Future<int> requestPhoneChange({
    required String phoneNumber,
    required String countryCode,
  }) async {
    final body = await _postContactChange(
      tag: 'Change-phone',
      endpoint: (e) => e.changePhone,
      unavailableMessage: 'Changing your phone number is not available right now',
      data: {'phone_number': phoneNumber, 'country_code': countryCode},
      fallback: 'Could not send the verification code',
    );
    // Phone verify needs the id, so a 200 without one is unusable.
    final otpId = _otpIdOf(body);
    if (otpId == null) {
      throw const ServerException(
        message: 'Could not send the verification code',
      );
    }
    return otpId;
  }

  @override
  Future<UserModel> verifyPhoneChange({
    required int otpId,
    required String otp,
  }) async {
    final body = await _postContactChange(
      tag: 'Change-phone-verify',
      endpoint: (e) => e.changePhoneVerify,
      unavailableMessage: 'Changing your phone number is not available right now',
      data: {'otp_id': otpId, 'otp': otp},
      fallback: 'Could not verify the code',
    );
    return _userOf(body, fallback: 'Could not verify the code');
  }

  /// Shared POST for the change-email / change-phone endpoints. Returns the
  /// envelope `body`; throws [ServerException] with the backend `message`
  /// (422/401), or a generic message for 400 "Request Failed".
  Future<dynamic> _postContactChange({
    required String tag,
    required String Function(ApiEndpoints endpoints) endpoint,
    required String unavailableMessage,
    required Map<String, dynamic> data,
    required String fallback,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final path = endpoint(config.apiConstants.apiEndpoints);
      if (path.trim().isEmpty) {
        throw ServerException(message: unavailableMessage);
      }

      final url = _buildUrl(ApiClient.baseUrl, path);
      AppLogger.d('[Auth] $tag URL: $url');

      final response = await apiClient.post(
        url,
        data: data,
        // The change-email/phone screens show the failure themselves; skip the
        // global toast so the message isn't shown twice.
        options: Options(extra: {ErrorInterceptor.silentKey: true}),
      );

      final responseData = response.data;
      if (response.statusCode == 200 && responseData is Map<String, dynamic>) {
        return responseData['body'];
      }

      throw ServerException(
        message: (responseData is Map<String, dynamic> &&
                responseData['message'] != null)
            ? responseData['message'].toString()
            : fallback,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      throw ServerException(
        // 400 is an unexpected server error — its message isn't user-facing.
        message: code == 400 ? _genericErrorMessage : _dioMessage(e, fallback: fallback),
        statusCode: code,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  static const String _genericErrorMessage =
      'Something went wrong. Please try again.';

  int? _otpIdOf(dynamic body) {
    final otpId = body is Map ? body['otp_id'] : null;
    return otpId is num ? otpId.toInt() : int.tryParse(otpId?.toString() ?? '');
  }

  /// The updated profile sits at `body.user` (same shape as `get_user`); the
  /// body itself is accepted too.
  UserModel _userOf(dynamic body, {required String fallback}) {
    final user = body is Map ? (body['user'] is Map ? body['user'] : body) : null;
    if (user is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(user));
    }
    throw ServerException(message: fallback);
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
      AppLogger.d('[Auth] Upload-user-picture URL: $url');

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

  @override
  Future<String> deleteAccount() async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.deleteAccount;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Deleting your account is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      AppLogger.d('[Auth] Delete-account URL: $url');

      // Authorized via the saved token by AuthInterceptor.
      final response = await apiClient.delete(url);

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
        return 'Your account has been deleted.';
      }

      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to delete your account',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Failed to delete your account'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> deleteUserPicture() async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.deleteUserPicture;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Removing your photo is not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      AppLogger.d('[Auth] Delete-user-picture URL: $url');

      // Authorized via the saved token by AuthInterceptor.
      final response = await apiClient.delete(url);

      final data = response.data;
      final isOk = response.statusCode == 200 &&
          (data is! Map || data['status'] == null || data['status'] == 200);
      if (isOk) return;

      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to remove picture',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Failed to remove picture'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Extracts a human-readable, user-safe message from a Dio error.
  ///
  /// Prefers the server's own `message`, which is present only when the request
  /// actually reached the backend and it returned an error body. When the
  /// request never completed — no internet, connection refused, timeouts — Dio's
  /// own `e.message` is raw internal text (e.g. "The connection errored:
  /// Connection refused This indicates an error which most likely cannot be
  /// solved by the library.") that must never be shown to users, so we map the
  /// failure type to a friendly message instead.
  String _dioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final serverMessage = data['message'].toString().trim();
      if (serverMessage.isNotEmpty) return serverMessage;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Please check your internet connection '
            'and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Please check your internet '
            'connection and try again.';
      case DioExceptionType.badCertificate:
        return "Please check your internet abd try again "
            'later.';
      case DioExceptionType.unknown:
        // Usually a SocketException — the device is offline or DNS failed.
        if (e.error is SocketException) {
          return 'Unable to reach the server. Please check your internet '
              'connection and try again.';
        }
        return fallback;
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
        return fallback;
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
      AppLogger.d('[Auth] Logout URL: $url');

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
      throw ServerException(
        message: _dioMessage(e, fallback: 'Logout failed'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }
}
