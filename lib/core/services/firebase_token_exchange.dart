import 'package:firebase_auth/firebase_auth.dart';

/// Exchanges a provider credential (Google / Apple) for a Firebase ID token.
///
/// The backend verifies `login_with_google`'s `token` with Firebase Admin
/// (`auth.verify_id_token`), which only accepts Firebase ID tokens — not the
/// raw Google / Apple tokens. The Firebase session is only needed to mint the
/// token (the backend issues its own), so it is signed out right after.
Future<String> firebaseIdTokenFor(AuthCredential credential) async {
  final auth = FirebaseAuth.instance;
  try {
    final result = await auth.signInWithCredential(credential);
    final token = await result.user?.getIdToken() ?? '';
    if (token.isEmpty) {
      throw StateError('Firebase sign-in returned no ID token');
    }
    return token;
  } finally {
    await auth.signOut();
  }
}
