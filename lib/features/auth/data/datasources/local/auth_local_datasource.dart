import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/domain/entities/login_method.dart';

/// Contract for local auth data operations (caching).
abstract class AuthLocalDataSource {
  /// Gets the cached user data.
  /// Throws [CacheException] if no data is present.
  Future<UserModel?> getCachedUser();

  /// Caches the user data locally.
  Future<void> cacheUser(UserModel user);

  /// Caches the auth tokens and records how the session was signed in.
  Future<void> cacheTokens({
    required String accessToken,
    String? refreshToken,
    LoginMethod loginMethod = LoginMethod.password,
  });

  /// Saves the token issued before OTP verification (sign-up, or login of an
  /// unverified account) WITHOUT marking the user logged in. The token is only
  /// usable for verify/resend OTP until [completePendingSession] is called.
  Future<void> cachePendingSession({required String accessToken});

  /// Promotes the pending session to a real login once the OTP is verified.
  Future<void> completePendingSession();

  /// Whether the cached session still awaits OTP verification.
  bool get isPendingOtpVerification;

  /// How the current session was signed in; `null` when unknown (no session,
  /// or one cached before the method was recorded).
  LoginMethod? get loginMethod;

  /// Clears all cached auth data.
  Future<void> clearCache();

  /// Checks whether tokens exist.
  bool get hasToken;

  /// The currently saved access token, or `null`/empty when none.
  String? get accessToken;
}
