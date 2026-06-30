import 'package:orko_hubco/features/auth/data/models/signup_result_model.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';

/// Contract for remote auth data operations.
abstract class AuthRemoteDataSource {
  /// Calls the login API (`login_api` endpoint from Remote Config).
  /// Returns the access token and user on success.
  /// Throws [ServerException] on failure.
  Future<SignUpResultModel> login({
    required String phoneNumber,
    required String countryCode,
    required String password,
  });

  /// Calls the Google sign-in API (`login_with_google` endpoint from Remote
  /// Config) with `{ name, email }`. Returns the access token and user.
  /// Throws [ServerException] on failure.
  Future<SignUpResultModel> loginWithGoogle({
    required String name,
    required String email,
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

  /// Requests a fresh OTP via the `resend_otp` endpoint from Remote Config.
  ///
  /// Two modes are supported:
  /// * Signup verification — pass [accessToken]; sent as a `Bearer`
  ///   Authorization header with no request body.
  /// * Sign-in OTP — pass [otpId]; sent as `{ "otp_id": <id> }` body.
  ///
  /// Returns the human-readable confirmation message from the response body.
  /// Throws [ServerException] on failure.
  Future<String> resendOtp({
    String? otpId,
    String? accessToken,
  });

  /// Step 1 of the forgot-password flow — `login_with_otp` endpoint (no auth).
  ///
  /// Sends `{ "email": <email> }` and returns the `otp_id` the backend issues,
  /// which must be passed to [verifyResetOtp]. Throws [ServerException].
  Future<int> loginWithOtp({required String email});

  /// Step 2 of the forgot-password flow — `verify_otp` endpoint (no auth).
  ///
  /// Sends `{ otp_id, otp }` and returns the short-lived `access` token the
  /// backend issues, which authorizes the [resetPassword] call. Throws
  /// [ServerException] on failure.
  Future<String> verifyResetOtp({required int otpId, required String otp});

  /// Step 3 of the forgot-password flow — `reset_password` endpoint
  /// (authenticated with the token from [verifyResetOtp]).
  ///
  /// Sends `{ new_password, confirm_password }` with `Bearer <accessToken>` and
  /// returns the server's confirmation message. Throws [ServerException].
  Future<String> resetPassword({
    required String accessToken,
    required String newPassword,
    required String confirmPassword,
  });

  /// Calls the logout API.
  Future<void> logout();

  /// Fetches the current logged-in user (`get_user` endpoint from Remote
  /// Config). Returns the parsed [UserModel] (`body.user`).
  /// Throws [ServerException] on failure.
  Future<UserModel> getUser();

  /// Updates the user profile via the `edit_user_profile` endpoint.
  ///
  /// [data] holds the snake_case fields to update (e.g. `name`, `email`,
  /// `phone_number`). Throws [ServerException] on failure.
  Future<void> editUserProfile(Map<String, dynamic> data);

  /// Uploads a new profile picture via the `upload_user_picture` endpoint.
  ///
  /// [imagePath] is the absolute path of the picked image file, sent as
  /// multipart form-data under the `image` field. Throws [ServerException] on
  /// failure.
  Future<void> uploadUserPicture(String imagePath);
}
