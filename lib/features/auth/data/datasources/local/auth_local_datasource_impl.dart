import 'dart:convert';

import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/router/auth_notifier.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';

/// Concrete implementation of [AuthLocalDataSource] using GetStorage.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorageService storageService;

  static const String _cachedUserKey = StorageConstants.cachedUser;

  const AuthLocalDataSourceImpl({required this.storageService});

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = storageService.read<String>(_cachedUserKey);
    if (jsonString == null) return null;

    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return UserModel.fromJson(jsonMap);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final jsonString = json.encode(user.toJson());
    await storageService.write(_cachedUserKey, jsonString);
  }

  @override
  Future<void> cacheTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await storageService.saveAccessToken(accessToken);
    if (refreshToken != null) {
      await storageService.saveRefreshToken(refreshToken);
    }
    await storageService.setLoggedIn(true);
    // A real session supersedes any guest mode.
    await storageService.setGuest(false);
    // Let the router re-evaluate its auth guard.
    AuthNotifier.instance.authChanged();
  }

  @override
  Future<void> clearCache() async {
    // Fully remove the encrypted secrets rather than blanking them, so nothing
    // sensitive lingers after logout.
    await storageService.remove(_cachedUserKey);
    await storageService.remove(StorageConstants.accessToken);
    await storageService.remove(StorageConstants.refreshToken);
    await storageService.remove(StorageConstants.userId);
    await storageService.setLoggedIn(false);
    await storageService.setGuest(false);
    // Let the router re-evaluate its auth guard.
    AuthNotifier.instance.authChanged();
  }

  @override
  bool get hasToken {
    final token = storageService.accessToken;
    return token != null && token.isNotEmpty;
  }

  @override
  String? get accessToken => storageService.accessToken;
}
