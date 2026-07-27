import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/secure_store.dart';

/// Abstraction over local key-value storage.
///
/// Security-sensitive keys ([SecureStore.secureKeys]: auth tokens, user id and
/// the cached user PII) are transparently routed to the encrypted
/// [SecureStore]; everything else stays in the plain GetStorage box.
class LocalStorageService {
  final GetStorage _box;
  final SecureStore _secure = SecureStore.instance;

  LocalStorageService() : _box = GetStorage();

  // ── Token Management (encrypted at rest) ────────────────────────────


  String? get accessToken => _secure.read(StorageConstants.accessToken);

  Future<void> saveAccessToken(String token) =>
      _secure.write(StorageConstants.accessToken, token);

  String? get refreshToken => _secure.read(StorageConstants.refreshToken);

  Future<void> saveRefreshToken(String token) =>
      _secure.write(StorageConstants.refreshToken, token);

  // ── Auth State (non-sensitive flags — plain box) ────────────────────

  bool get isLoggedIn => _box.read<bool>(StorageConstants.isLoggedIn) ?? false;

  Future<void> setLoggedIn(bool value) =>
      _box.write(StorageConstants.isLoggedIn, value);

  /// Whether the user is browsing as a guest (no authenticated session).
  bool get isGuest => _box.read<bool>(StorageConstants.isGuest) ?? false;

  Future<void> setGuest(bool value) =>
      _box.write(StorageConstants.isGuest, value);

  // ── User (encrypted at rest) ────────────────────────────────────────

  String? get userId => _secure.read(StorageConstants.userId);

  Future<void> saveUserId(String id) =>
      _secure.write(StorageConstants.userId, id);

  // ── Generic ─────────────────────────────────────────────────────────
  // Secret keys are routed to the encrypted store; all other keys use the
  // plain GetStorage box.

  T? read<T>(String key) {
    if (SecureStore.secureKeys.contains(key)) {
      return _secure.read(key) as T?;
    }
    return _box.read<T>(key);
  }

  Future<void> write(String key, dynamic value) {
    if (SecureStore.secureKeys.contains(key)) {
      return _secure.write(key, value as String);
    }
    return _box.write(key, value);
  }

  Future<void> remove(String key) {
    if (SecureStore.secureKeys.contains(key)) {
      return _secure.delete(key);
    }
    return _box.remove(key);
  }

  Future<void> clearAll() async {
    await _secure.clear();
    await _box.erase();
  }
}
