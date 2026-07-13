import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';

/// Abstract repository contract — lives in the domain layer.
/// The data layer provides the implementation.
abstract class AuthRepository {
  /// Logs in with phone number, country code and password via the `login_api`
  /// endpoint. Persists the issued access token + user, and returns the
  /// [SignUpResultEntity] on success or a [Failure] on error.
  Future<Either<Failure, SignUpResultEntity>> login({
    required String phoneNumber,
    required String countryCode,
    required String password,
  });

  /// Authenticates with a Google account via the `login_with_google` endpoint.
  /// Sends `{ name, email }`, persists the issued access token + user, and
  /// returns the [SignUpResultEntity] on success or a [Failure] on error.
  Future<Either<Failure, SignUpResultEntity>> loginWithGoogle({
    required String name,
    required String email,
  });

  /// Completes sign-up via the `sign_up_form` endpoint, persisting the issued
  /// access token locally. Returns the [SignUpResultEntity] on success.
  Future<Either<Failure, SignUpResultEntity>> signUp({
    required String name,
    required String phoneNumber,
    required String countryCode,
    required String email,
    required String password,
    required String confirmPassword,
  });

  /// Verifies the OTP via the `verify_otp` endpoint, authorizing with the
  /// access token saved at sign-up.
  Future<Either<Failure, void>> verifyOtp({required String otp});

  /// Requests a fresh OTP via the `resend_otp` endpoint.
  ///
  /// When [otpId] is omitted, authorizes with the access token saved at
  /// sign-up (signup verification flow). When [otpId] is provided, identifies
  /// the pending OTP by id (sign-in flow). Returns the confirmation message.
  Future<Either<Failure, String>> resendOtp({String? otpId});

  /// Forgot-password step 1 — requests an OTP via `login_with_otp`. Returns the
  /// issued `otp_id` to use with [verifyResetOtp].
  Future<Either<Failure, int>> loginWithOtp({required String email});

  /// Forgot-password step 2 — verifies the OTP via `verify_otp` and returns the
  /// short-lived access token that authorizes [resetPassword].
  Future<Either<Failure, String>> verifyResetOtp({
    required int otpId,
    required String otp,
  });

  /// Forgot-password step 3 — sets a new password via `reset_password`,
  /// authorized with the token from [verifyResetOtp]. Returns the confirmation
  /// message on success.
  Future<Either<Failure, String>> resetPassword({
    required String accessToken,
    required String newPassword,
    required String confirmPassword,
  });

  /// Logs out the current user.
  Future<Either<Failure, void>> logout();

  /// Permanently deletes the current user's account via the `delete_account`
  /// endpoint, then clears local cache. Returns the confirmation message.
  Future<Either<Failure, String>> deleteAccount();

  /// Checks if a user is currently authenticated.
  Future<Either<Failure, bool>> isAuthenticated();

  /// Fetches the current user from the `get_user` endpoint and refreshes the
  /// locally cached user. Returns the up-to-date [UserEntity].
  Future<Either<Failure, UserEntity>> getUser();

  /// Updates the user profile via the `edit_user_profile` endpoint, then
  /// re-fetches the user (`get_user`) and refreshes the cached user. Returns
  /// the up-to-date [UserEntity].
  Future<Either<Failure, UserEntity>> editUserProfile(
    Map<String, dynamic> data,
  );

  /// Step 1 of the email-change flow: requests an OTP be sent to [newEmail]
  /// via the `change_email` endpoint. Returns the issued `otp_id`.
  Future<Either<Failure, int>> requestEmailChange(String newEmail);

  /// Step 2 of the email-change flow: verifies [otp] via the
  /// `change_email_verify` endpoint, then refreshes the cached user. Returns
  /// the up-to-date [UserEntity] with the new email.
  Future<Either<Failure, UserEntity>> verifyEmailChange(String otp);

  /// Uploads a new profile picture via the `upload_user_picture` endpoint,
  /// then re-fetches the user (`get_user`) and refreshes the cached user.
  /// Returns the up-to-date [UserEntity].
  Future<Either<Failure, UserEntity>> uploadUserPicture(String imagePath);

  /// Removes the profile picture via the `delete_user_picture` endpoint, then
  /// re-fetches the user (`get_user`) and refreshes the cached user. Returns
  /// the up-to-date [UserEntity].
  Future<Either<Failure, UserEntity>> deleteUserPicture();
}
