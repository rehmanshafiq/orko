/// How the current session was signed in.
///
/// Kept locally because the backend's user object doesn't carry the sign-in
/// provider. Written when a session is cached and removed when it is cleared.
enum LoginMethod {
  password,
  google,
  apple;

  /// Parses a stored [name]; `null` for a missing or unknown value (e.g. a
  /// session cached before this was recorded).
  static LoginMethod? fromName(String? name) {
    for (final method in values) {
      if (method.name == name) return method;
    }
    return null;
  }
}
