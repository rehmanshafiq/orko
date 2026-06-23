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
}
