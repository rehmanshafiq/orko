import 'package:orko_hubco/features/auth/data/models/signup_result_model.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';

/// Contract for remote auth data operations.
abstract class AuthRemoteDataSource {
  /// Calls the login API.
  /// Throws [ServerException] on failure.
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Calls the register API.
  /// Throws [ServerException] on failure.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  /// Calls the complete-signup API (`sign_up_form` endpoint from Remote Config).
  /// Returns the access token and created user.
  /// Throws [ServerException] on failure.
  Future<SignUpResultModel> completeSignup({
    required String name,
    required String phoneNumber,
    required String countryCode,
    required String email,
    required String password,
    required String confirmPassword,
  });

  /// Verifies the OTP via the `verify_otp` endpoint from Remote Config.
  ///
  /// Sends `{ "otp": <otp> }` with the saved [accessToken] as a
  /// `Bearer` Authorization header.
  /// Throws [ServerException] on failure.
  Future<void> verifyOtp({
    required String otp,
    required String accessToken,
  });

  /// Calls the logout API.
  Future<void> logout();
}
