import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';

class AppStorage {
  AppStorage._();

  static final GetStorage _storage = GetStorage();

  static bool get isOnboardingCompleted =>
      _storage.read<bool>(StorageConstants.onboardingComplete) ?? false;

  static Future<void> setOnboardingCompleted(bool value) {
    return _storage.write(StorageConstants.onboardingComplete, value);
  }

  /// Whether the user chose to continue as a guest (no authenticated session).
  static bool get isGuest =>
      _storage.read<bool>(StorageConstants.isGuest) ?? false;

  static Future<void> setGuest(bool value) {
    return _storage.write(StorageConstants.isGuest, value);
  }

  /// Latest FCM device token (empty when not yet resolved). Read by the auth
  /// data source to attach `token` to the login request.
  static String get fcmToken =>
      _storage.read<String>(StorageConstants.fcmToken) ?? '';

  static Future<void> setFcmToken(String token) {
    return _storage.write(StorageConstants.fcmToken, token);
  }

  /// FCM token last successfully registered with the backend (empty if none).
  static String get fcmTokenRegistered =>
      _storage.read<String>(StorageConstants.fcmTokenRegistered) ?? '';

  static Future<void> setFcmTokenRegistered(String token) {
    return _storage.write(StorageConstants.fcmTokenRegistered, token);
  }

  /// Id of the charging session last seen active on `live-session/`, or null
  /// when none is pending. Non-null after the app kills/relaunches mid-session,
  /// which is what lets the post-session summary appear on the next visit to
  /// the bookings or charging screens.
  static int? get activeChargeSessionId {
    final value = _storage.read(StorageConstants.activeChargeSessionId);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Future<void> setActiveChargeSessionId(int sessionId) {
    return _storage.write(StorageConstants.activeChargeSessionId, sessionId);
  }

  /// Called once the session summary has been shown and dismissed.
  static Future<void> clearActiveChargeSessionId() {
    return _storage.remove(StorageConstants.activeChargeSessionId);
  }

  // ── Sign in with Apple ────────────────────────────────────────────────
  // Apple only returns the user's name + email on the first authorization for
  // an app; later sign-ins return them as null. We persist them keyed by the
  // stable `userIdentifier` so subsequent logins can still reconstruct the
  // `{name, email}` payload the backend expects.

  static String _appleKey(String userIdentifier) =>
      '${StorageConstants.appleAccountPrefix}$userIdentifier';

  /// Returns the cached `{name, email}` for [userIdentifier], or null if the
  /// user has never been captured on this device.
  static ({String? name, String? email})? appleAccount(String userIdentifier) {
    if (userIdentifier.isEmpty) return null;
    final value = _storage.read(_appleKey(userIdentifier));
    if (value is! Map) return null;
    return (
      name: value['name']?.toString(),
      email: value['email']?.toString(),
    );
  }

  /// Caches the name/email captured on the first Apple sign-in. Only writes the
  /// fields that are non-empty so a later (empty) response never clobbers a
  /// value captured earlier.
  static Future<void> cacheAppleAccount({
    required String userIdentifier,
    String? name,
    String? email,
  }) {
    if (userIdentifier.isEmpty) return Future<void>.value();
    final existing = appleAccount(userIdentifier);
    final mergedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : existing?.name;
    final mergedEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim()
        : existing?.email;
    return _storage.write(_appleKey(userIdentifier), {
      'name': mergedName,
      'email': mergedEmail,
    });
  }
}
