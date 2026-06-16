import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Global light/dark theme. Persists [StorageConstants.themeMode] via [LocalStorageService].
///
/// Defaults to dark on first install and after reinstall (Android may restore
/// backed-up storage from a previous install).
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit._(this._storage, ThemeMode initial) : super(initial);

  final LocalStorageService _storage;

  static Future<ThemeCubit> create({
    required LocalStorageService localStorageService,
  }) async {
    final mode = await _resolveInitialTheme(localStorageService);
    return ThemeCubit._(localStorageService, mode);
  }

  static Future<ThemeMode> _resolveInitialTheme(
    LocalStorageService storage,
  ) async {
    if (await _shouldResetToDefaultTheme(storage)) {
      await storage.write(StorageConstants.themeMode, 'dark');
      return ThemeMode.dark;
    }

    final raw = storage.read<String>(StorageConstants.themeMode);
    return raw == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  /// Returns true after reinstall when backup restored an old install marker.
  static Future<bool> _shouldResetToDefaultTheme(
    LocalStorageService storage,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final installTimeMs = packageInfo.installTime?.millisecondsSinceEpoch;
    if (installTimeMs == null) return false;

    final storedInstallTime =
        storage.read<int>(StorageConstants.appInstallTime);
    if (storedInstallTime == null) {
      await storage.write(StorageConstants.appInstallTime, installTimeMs);
      return false;
    }

    if (storedInstallTime != installTimeMs) {
      await storage.write(StorageConstants.appInstallTime, installTimeMs);
      return true;
    }

    return false;
  }

  void setThemeMode(ThemeMode mode) {
    if (state == mode) return;
    emit(mode);
    _storage.write(
      StorageConstants.themeMode,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  void setLight() => setThemeMode(ThemeMode.light);

  void setDark() => setThemeMode(ThemeMode.dark);
}
