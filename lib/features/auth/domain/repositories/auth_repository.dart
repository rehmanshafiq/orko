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

  /// Registers a new user.
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
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

  /// Logs out the current user.
  Future<Either<Failure, void>> logout();

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

  /// Uploads a new profile picture via the `upload_user_picture` endpoint,
  /// then re-fetches the user (`get_user`) and refreshes the cached user.
  /// Returns the up-to-date [UserEntity].
  Future<Either<Failure, UserEntity>> uploadUserPicture(String imagePath);
}
