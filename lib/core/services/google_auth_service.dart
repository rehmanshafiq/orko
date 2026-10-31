import 'package:firebase_auth/firebase_auth.dart' show GoogleAuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orko_hubco/core/services/firebase_token_exchange.dart';

/// Minimal account info we need from a Google sign-in to authenticate with the
/// backend (`login_with_google` expects `{ name, email, token }`).
class GoogleAccountInfo {
  const GoogleAccountInfo({
    required this.name,
    required this.email,
    required this.firebaseIdToken,
  });

  final String name;
  final String email;

  /// Firebase ID token minted from the Google credential; the backend verifies
  /// it with Firebase Admin.
  final String firebaseIdToken;
}

/// Thin wrapper around [GoogleSignIn] that exposes the native account picker and
/// returns just the fields the backend requires.
///
/// Keeping this in the service layer lets the auth repository / cubit stay
/// platform-agnostic and testable.
class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: const ['email', 'profile']);

  final GoogleSignIn _googleSignIn;

  /// Launches the Google account picker.
  ///
  /// Returns the selected account's name + email, or `null` if the user
  /// dismissed the picker. Throws if the platform sign-in itself fails (e.g.
  /// misconfigured SHA-1 / network), so callers can surface an error.
  Future<GoogleAccountInfo?> signIn() async {
    // Sign out first so the chooser is shown every time instead of silently
    // reusing the last account.
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) return null; // user cancelled

    final email = account.email.trim();
    if (email.isEmpty) return null;

    // On Android the ID token is only issued when a web OAuth client exists in
    // google-services.json (used as the server client ID).
    final googleAuth = await account.authentication;
    final googleIdToken = googleAuth.idToken ?? '';
    if (googleIdToken.isEmpty) {
      throw StateError('Google sign-in returned no ID token');
    }

    final firebaseIdToken = await firebaseIdTokenFor(
      GoogleAuthProvider.credential(
        idToken: googleIdToken,
        accessToken: googleAuth.accessToken,
      ),
    );

    final name = (account.displayName ?? '').trim();
    return GoogleAccountInfo(
      // Fall back to the local-part of the email if Google withholds the name.
      name: name.isNotEmpty ? name : email.split('@').first,
      email: email,
      firebaseIdToken: firebaseIdToken,
    );
  }

  /// Clears the cached Google session (called on logout if needed).
  Future<void> signOut() => _googleSignIn.signOut();
}
