import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Raised when Sign in with Apple completed but we could not derive an email to
/// send to the backend. This happens in the rare case where Apple no longer
/// returns the email (already authorized once) *and* nothing was cached on this
/// device — e.g. after a reinstall combined with the app still being listed
/// under the Apple ID's "Sign in with Apple" apps. The message is user-facing.
class AppleEmailUnavailableException implements Exception {
  const AppleEmailUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'AppleEmailUnavailableException: $message';
}

/// Minimal account info we need from an Apple sign-in to authenticate with the
/// backend. Mirrors [GoogleAccountInfo] so the same `{ name, email }` payload /
/// `login_with_google` endpoint can be reused for both providers.
class AppleAccountInfo {
  const AppleAccountInfo({required this.name, required this.email});

  final String name;
  final String email;
}

/// Thin wrapper around [SignInWithApple] that runs the native authorization
/// flow and returns just the fields the backend requires.
///
/// Apple only surfaces the user's name + email on the *first* authorization for
/// this app; every later sign-in returns them as null. To keep later logins
/// working we cache them keyed by Apple's stable `userIdentifier`
/// ([AppStorage.cacheAppleAccount]) and fall back to the cache when Apple
/// withholds them.
class AppleAuthService {
  const AppleAuthService();

  /// Whether Sign in with Apple is supported on this device. Always false on
  /// non-Apple platforms and on iOS versions below 13. Callers should hide the
  /// Apple button when this is false.
  Future<bool> isAvailable() {
    return SignInWithApple.isAvailable();
  }

  /// Launches the native Apple authorization sheet.
  ///
  /// Returns the account's name + email, or `null` if the user cancelled the
  /// sheet (no error surfaced to the user, matching the Google flow). Throws
  /// [AppleEmailUnavailableException] with a readable message when the sign-in
  /// succeeds but no email can be resolved, or rethrows the underlying
  /// [SignInWithAppleException] for genuine failures so the caller can surface
  /// a generic error.
  Future<AppleAccountInfo?> signIn() async {
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // User dismissed / cancelled the sheet — treat like Google cancellation.
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    final userIdentifier = credential.userIdentifier ?? '';

    // Apple returns the name only on the first authorization; build it from the
    // parts it gives us and fall back to the cache on later sign-ins.
    final fullName = [credential.givenName, credential.familyName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' ')
        .trim();

    final email = credential.email?.trim() ?? '';

    // Persist whatever Apple just gave us (merge — never clobber with blanks).
    if (userIdentifier.isNotEmpty && (fullName.isNotEmpty || email.isNotEmpty)) {
      await AppStorage.cacheAppleAccount(
        userIdentifier: userIdentifier,
        name: fullName.isNotEmpty ? fullName : null,
        email: email.isNotEmpty ? email : null,
      );
    }

    final cached = AppStorage.appleAccount(userIdentifier);

    final resolvedEmail =
        email.isNotEmpty ? email : (cached?.email?.trim() ?? '');
    if (resolvedEmail.isEmpty) {
      throw const AppleEmailUnavailableException(
        'We couldn\'t get your Apple email. In Settings → your name → '
        'Sign in with Apple, remove this app, then try again.',
      );
    }

    final resolvedName = fullName.isNotEmpty
        ? fullName
        : ((cached?.name?.trim().isNotEmpty ?? false)
            ? cached!.name!.trim()
            // Last resort: derive a display name from the email local-part,
            // matching the Google service's fallback.
            : resolvedEmail.split('@').first);

    return AppleAccountInfo(name: resolvedName, email: resolvedEmail);
  }
}
