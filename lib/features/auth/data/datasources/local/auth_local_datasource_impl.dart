import 'dart:convert';

import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';

/// Concrete implementation of [AuthLocalDataSource] using GetStorage.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorageService storageService;

  static const String _cachedUserKey = 'cached_user';

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
  }

  @override
  Future<void> clearCache() async {
    await storageService.remove(_cachedUserKey);
    await storageService.saveAccessToken('');
    await storageService.saveRefreshToken('');
    await storageService.setLoggedIn(false);
  }

  @override
  bool get hasToken {
    final token = storageService.accessToken;
    return token != null && token.isNotEmpty;
  }
}
