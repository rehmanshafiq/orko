import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';

/// Global light/dark theme. Persists [StorageConstants.themeMode] via [LocalStorageService].
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required LocalStorageService localStorageService})
      : _storage = localStorageService,
        super(_readInitial(localStorageService));

  final LocalStorageService _storage;

  static ThemeMode _readInitial(LocalStorageService storage) {
    final raw = storage.read<String>(StorageConstants.themeMode);
    return raw == 'light' ? ThemeMode.light : ThemeMode.dark;
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
