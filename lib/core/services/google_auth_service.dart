import 'package:google_sign_in/google_sign_in.dart';

/// Minimal account info we need from a Google sign-in to authenticate with the
/// backend (`login_with_google` expects `{ name, email }`).
class GoogleAccountInfo {
  const GoogleAccountInfo({required this.name, required this.email});

  final String name;
  final String email;
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

    final name = (account.displayName ?? '').trim();
    return GoogleAccountInfo(
      // Fall back to the local-part of the email if Google withholds the name.
      name: name.isNotEmpty ? name : email.split('@').first,
      email: email,
    );
  }

  /// Clears the cached Google session (called on logout if needed).
  Future<void> signOut() => _googleSignIn.signOut();
}
