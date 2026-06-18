import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';

/// Abstract repository contract — lives in the domain layer.
/// The data layer provides the implementation.
abstract class AuthRepository {
  /// Logs in with email and password.
  /// Returns [UserEntity] on success or [Failure] on error.
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
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

  /// Logs out the current user.
  Future<Either<Failure, void>> logout();

  /// Checks if a user is currently authenticated.
  Future<Either<Failure, bool>> isAuthenticated();
}
