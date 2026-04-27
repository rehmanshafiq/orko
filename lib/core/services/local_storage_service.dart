import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';

/// Abstraction over local key-value storage.
class LocalStorageService {
  final GetStorage _box;

  LocalStorageService() : _box = GetStorage();

  // ── Token Management ────────────────────────────────────────────────

  String? get accessToken => _box.read<String>(StorageConstants.accessToken);

  Future<void> saveAccessToken(String token) =>
      _box.write(StorageConstants.accessToken, token);

  String? get refreshToken => _box.read<String>(StorageConstants.refreshToken);

  Future<void> saveRefreshToken(String token) =>
      _box.write(StorageConstants.refreshToken, token);

  // ── Auth State ──────────────────────────────────────────────────────

  bool get isLoggedIn => _box.read<bool>(StorageConstants.isLoggedIn) ?? false;

  Future<void> setLoggedIn(bool value) =>
      _box.write(StorageConstants.isLoggedIn, value);

  // ── User ────────────────────────────────────────────────────────────

  String? get userId => _box.read<String>(StorageConstants.userId);

  Future<void> saveUserId(String id) =>
      _box.write(StorageConstants.userId, id);

  // ── Generic ─────────────────────────────────────────────────────────

  T? read<T>(String key) => _box.read<T>(key);

  Future<void> write(String key, dynamic value) => _box.write(key, value);

  Future<void> remove(String key) => _box.remove(key);

  Future<void> clearAll() => _box.erase();
}
