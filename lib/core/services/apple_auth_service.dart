import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show AppleAuthProvider, AppleFullPersonName;
import 'package:orko_hubco/core/services/firebase_token_exchange.dart';
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
  const AppleAccountInfo({
    required this.name,
    required this.email,
    required this.firebaseIdToken,
  });

  final String name;
  final String email;

  /// Firebase ID token minted from the Apple credential; the backend verifies
  /// it with Firebase Admin.
  final String firebaseIdToken;
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
    // Firebase requires a nonce: Apple embeds its SHA-256 in the identity
    // token, and Firebase checks it against the raw value.
    final rawNonce = _generateNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // User dismissed / cancelled the sheet — treat like Google cancellation.
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    final userIdentifier = credential.userIdentifier ?? '';
    final identityToken = credential.identityToken ?? '';
    if (identityToken.isEmpty) {
      throw StateError('Apple sign-in returned no identity token');
    }

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

    // Apple sends `credential.email` only on the first authorization, but the
    // identity token carries the email claim on every sign-in — use it before
    // the device cache (which is lost on reinstall).
    final resolvedEmail = email.isNotEmpty
        ? email
        : (_emailFromIdentityToken(identityToken) ??
            cached?.email?.trim() ??
            '');
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

    final firebaseIdToken = await firebaseIdTokenFor(
      AppleAuthProvider.credentialWithIDToken(
        identityToken,
        rawNonce,
        AppleFullPersonName(
          givenName: credential.givenName,
          familyName: credential.familyName,
        ),
      ),
    );

    return AppleAccountInfo(
      name: resolvedName,
      email: resolvedEmail,
      firebaseIdToken: firebaseIdToken,
    );
  }

  /// Reads the `email` claim from Apple's identity token (a JWT), or `null` if
  /// it is missing or the token can't be decoded.
  static String? _emailFromIdentityToken(String identityToken) {
    try {
      final payload = identityToken.split('.')[1];
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      );
      final email = claims is Map ? claims['email'] : null;
      return email is String && email.trim().isNotEmpty ? email.trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// Cryptographically secure random nonce for the Apple / Firebase exchange.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
