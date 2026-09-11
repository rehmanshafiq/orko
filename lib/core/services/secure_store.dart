import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

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
///
/// Android EncryptedSharedPreferences / Keystore can stall (especially on
/// first install). We bound platform I/O and, once it times out, stop issuing
/// further plugin calls for the rest of the process so auth flows cannot hang
/// forever waiting on a stuck channel. The in-memory mirror still works for
/// the current session.
class SecureStore {
  SecureStore._();

  /// Shared singleton.
  static final SecureStore instance = SecureStore._();

  /// Bound for Keystore / EncryptedSharedPreferences work during startup.
  static const Duration _initTimeout = Duration(seconds: 5);

  /// Bound for individual persist operations after a successful login.
  static const Duration _persistTimeout = Duration(seconds: 5);

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Corrupted master keys otherwise leave reads hanging / failing forever.
      resetOnError: true,
    ),
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

  /// When false, skip further EncryptedSharedPreferences calls — a prior
  /// timeout almost certainly left a platform-channel call pending, and
  /// awaiting another one would freeze login/logout indefinitely.
  bool _platformAvailable = true;

  /// Loads secure values into the in-memory mirror and migrates any legacy
  /// plaintext values written by earlier app versions out of GetStorage.
  ///
  /// Call once in `main()` after `GetStorage.init()` and before `runApp()` /
  /// the first API call. Idempotent.
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _loadMirrorAndMigrate().timeout(_initTimeout);
    } on TimeoutException {
      _platformAvailable = false;
      AppLogger.d(
        '[SecureStore] init timed out after ${_initTimeout.inSeconds}s; '
        'continuing with in-memory store only for this session',
      );
    } catch (error, stackTrace) {
      _platformAvailable = false;
      AppLogger.d('[SecureStore] init failed: $error\n$stackTrace');
    }

    _initialized = true;
  }

  Future<void> _loadMirrorAndMigrate() async {
    for (final key in secureKeys) {
      final value = await _secure.read(key: key);
      if (value != null && value.isNotEmpty) _mirror[key] = value;
    }

    await _migrateLegacyPlaintext();
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
        await _persistWrite(key, legacy);
      }
      // Remove any plaintext residue (including the empty strings older logout
      // code used to write).
      if (box.hasData(key)) await box.remove(key);
    }
  }

  bool containsKey(String key) => _mirror.containsKey(key);

  /// Synchronous read from the in-memory mirror. Returns null when absent.
  String? read(String key) => _mirror[key];

  /// Updates the mirror immediately so auth/API can proceed, then best-effort
  /// persists to the encrypted store without blocking the caller. A stuck
  /// Android Keystore must never keep Google/phone login spinning forever.
  Future<void> write(String key, String value) async {
    _mirror[key] = value;
    unawaited(_persistWrite(key, value));
  }

  /// Removes [key] from the mirror immediately, then best-effort deletes from
  /// the encrypted store.
  Future<void> delete(String key) async {
    _mirror.remove(key);
    unawaited(_persistDelete(key));
  }

  /// Clears every secret (call on logout).
  Future<void> clear() async {
    _mirror.clear();
    if (!_platformAvailable) return;
    for (final key in secureKeys) {
      await _persistDelete(key);
    }
  }

  Future<void> _persistWrite(String key, String value) async {
    if (!_platformAvailable) return;
    try {
      await _secure.write(key: key, value: value).timeout(_persistTimeout);
    } on TimeoutException {
      _platformAvailable = false;
      AppLogger.d(
        '[SecureStore] write($key) timed out; disabling platform persist '
        'for this session',
      );
    } catch (error, stackTrace) {
      AppLogger.d('[SecureStore] write($key) failed: $error\n$stackTrace');
    }
  }

  Future<void> _persistDelete(String key) async {
    if (!_platformAvailable) return;
    try {
      await _secure.delete(key: key).timeout(_persistTimeout);
    } on TimeoutException {
      _platformAvailable = false;
      AppLogger.d(
        '[SecureStore] delete($key) timed out; disabling platform persist '
        'for this session',
      );
    } catch (error, stackTrace) {
      AppLogger.d('[SecureStore] delete($key) failed: $error\n$stackTrace');
    }
  }
}
