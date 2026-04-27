import 'package:orko_hubco/features/auth/data/models/user_model.dart';

/// Contract for local auth data operations (caching).
abstract class AuthLocalDataSource {
  /// Gets the cached user data.
  /// Throws [CacheException] if no data is present.
  Future<UserModel?> getCachedUser();

  /// Caches the user data locally.
  Future<void> cacheUser(UserModel user);

  /// Caches the auth tokens.
  Future<void> cacheTokens({
    required String accessToken,
    String? refreshToken,
  });

  /// Clears all cached auth data.
  Future<void> clearCache();

  /// Checks whether tokens exist.
  bool get hasToken;
}
