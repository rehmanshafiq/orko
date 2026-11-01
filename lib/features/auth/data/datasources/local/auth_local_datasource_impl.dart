import 'dart:convert';

import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/router/auth_notifier.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/domain/entities/login_method.dart';

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
    LoginMethod loginMethod = LoginMethod.password,
  }) async {
    await storageService.saveAccessToken(accessToken);
    if (refreshToken != null) {
      await storageService.saveRefreshToken(refreshToken);
    }
    // Overwrites any method left by a previous account on this device.
    await storageService.write(StorageConstants.loginMethod, loginMethod.name);
    await storageService.setLoggedIn(true);
    await storageService.setPendingOtpVerification(false);
    // A real session supersedes any guest mode.
    await storageService.setGuest(false);
    // Let the router re-evaluate its auth guard.
    AuthNotifier.instance.authChanged();
  }

  @override
  Future<void> cachePendingSession({required String accessToken}) async {
    if (accessToken.isNotEmpty) {
      await storageService.saveAccessToken(accessToken);
    }
    // OTP-pending sessions only come from password sign-up / login.
    await storageService.write(
      StorageConstants.loginMethod,
      LoginMethod.password.name,
    );
    await storageService.setPendingOtpVerification(true);
    await storageService.setLoggedIn(false);
    await storageService.setGuest(false);
    AuthNotifier.instance.authChanged();
  }

  @override
  Future<void> completePendingSession() async {
    await storageService.setPendingOtpVerification(false);
    await storageService.setLoggedIn(true);
    await storageService.setGuest(false);
    // The cached user came from sign-up/login and still says verification is
    // required; verify-otp returns no user, so clear the flag locally.
    final user = await getCachedUser();
    if (user != null && user.otpVerificationRequired) {
      await cacheUser(user.copyWith(otpVerificationRequired: false));
    }
    AuthNotifier.instance.authChanged();
  }

  @override
  bool get isPendingOtpVerification => storageService.isPendingOtpVerification;

  @override
  LoginMethod? get loginMethod => LoginMethod.fromName(
        storageService.read<String>(StorageConstants.loginMethod),
      );

  @override
  Future<void> clearCache() async {
    // Fully remove the encrypted secrets rather than blanking them, so nothing
    // sensitive lingers after logout.
    await storageService.remove(_cachedUserKey);
    await storageService.remove(StorageConstants.accessToken);
    await storageService.remove(StorageConstants.refreshToken);
    await storageService.remove(StorageConstants.userId);
    await storageService.remove(StorageConstants.loginMethod);
    await storageService.setLoggedIn(false);
    await storageService.setPendingOtpVerification(false);
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
