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
}
