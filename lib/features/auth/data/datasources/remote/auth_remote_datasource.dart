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

  /// Calls the logout API.
  Future<void> logout();
}
