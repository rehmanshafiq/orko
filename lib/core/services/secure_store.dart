import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';

/// Encrypted-at-rest storage for security-sensitive values — auth tokens and
/// user PII — backed by the iOS Keychain / Android EncryptedSharedPreferences
/// via `flutter_secure_storage`.
///
/// `flutter_secure_storage` is async-only, but many call sites read these
/// values synchronously (the Dio auth interceptor, widget `build` methods).
/// To keep those working without a large refactor, this service keeps a small
/// in-memory mirror that is loaded once at startup ([init]): reads are served
/// from the mirror, writes update the mirror synchronously and persist to the
/// encrypted store asynchronously.
///
/// Only the keys in [secureKeys] are encrypted; everything else stays in the
/// plain GetStorage box (theme, locale, onboarding flags, FCM tokens, …).
class SecureStore {
  SecureStore._();

  /// Shared singleton.
  static final SecureStore instance = SecureStore._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Keys whose values must be encrypted at rest.
  static const Set<String> secureKeys = {
    StorageConstants.accessToken,
    StorageConstants.refreshToken,
    StorageConstants.userId,
    StorageConstants.cachedUser,
  };

  final Map<String, String> _mirror = {};
  bool _initialized = false;

  /// Loads secure values into the in-memory mirror and migrates any legacy
  /// plaintext values written by earlier app versions out of GetStorage.
  ///
  /// Call once in `main()` after `GetStorage.init()` and before `runApp()` /
  /// the first API call. Idempotent.
  Future<void> init() async {
    if (_initialized) return;

    for (final key in secureKeys) {
      final value = await _secure.read(key: key);
      if (value != null && value.isNotEmpty) _mirror[key] = value;
    }

    await _migrateLegacyPlaintext();
    _initialized = true;
  }

  /// One-time upgrade path: move any secret still sitting in the unencrypted
  /// GetStorage box into the encrypted store, then erase the plaintext copy so
  /// it no longer lingers on disk.
  Future<void> _migrateLegacyPlaintext() async {
    final box = GetStorage();
    for (final key in secureKeys) {
      final legacy = box.read(key);
      if (legacy is String &&
          legacy.isNotEmpty &&
          !_mirror.containsKey(key)) {
        _mirror[key] = legacy;
        await _secure.write(key: key, value: legacy);
      }
      // Remove any plaintext residue (including the empty strings older logout
      // code used to write).
      if (box.hasData(key)) await box.remove(key);
    }
  }

  bool containsKey(String key) => _mirror.containsKey(key);

  /// Synchronous read from the in-memory mirror. Returns null when absent.
  String? read(String key) => _mirror[key];

  /// Persists [value] to the encrypted store and updates the mirror.
  Future<void> write(String key, String value) async {
    _mirror[key] = value;
    await _secure.write(key: key, value: value);
  }

  /// Removes [key] from the encrypted store and the mirror.
  Future<void> delete(String key) async {
    _mirror.remove(key);
    await _secure.delete(key: key);
  }

  /// Clears every secret (call on logout).
  Future<void> clear() async {
    _mirror.clear();
    for (final key in secureKeys) {
      await _secure.delete(key: key);
    }
  }
}
