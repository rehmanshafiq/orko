import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] to re-evaluate its `redirect` guard whenever the auth
/// session changes (login, logout, token cleared). Pinged from the auth local
/// data source so an in-flight authenticated screen is re-guarded immediately
/// after a forced logout.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier._();

  static final AuthNotifier instance = AuthNotifier._();

  /// Call after tokens are cached or cleared.
  void authChanged() => notifyListeners();
}
