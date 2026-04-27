import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';

/// Data source wrapping Firebase Remote Config.
abstract class RemoteConfigDataSource {
  Future<RemoteConfigModel> fetchConfig();
  String getString(String key, {String defaultValue = ''});
  bool getBool(String key, {bool defaultValue = false});
  int getInt(String key, {int defaultValue = 0});
}

class RemoteConfigDataSourceImpl implements RemoteConfigDataSource {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigDataSourceImpl({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  /// Initialize with defaults and fetch settings.
  Future<void> init() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Set default values
    await _remoteConfig.setDefaults({
      'maintenance_mode': false,
      'minimum_app_version': '1.0.0',
      'force_update': false,
      'promo_message': '',
    });
  }

  @override
  Future<RemoteConfigModel> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();

      return RemoteConfigModel(
        maintenanceMode: _remoteConfig.getBool('maintenance_mode'),
        minimumAppVersion: _remoteConfig.getString('minimum_app_version'),
        forceUpdate: _remoteConfig.getBool('force_update'),
        promoMessage: _remoteConfig.getString('promo_message'),
      );
    } catch (e) {
      log('[RemoteConfig] Fetch failed: $e');
      throw ServerException(message: 'Failed to fetch remote config', originalError: e);
    }
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    return _remoteConfig.getString(key);
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return _remoteConfig.getBool(key);
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    return _remoteConfig.getInt(key);
  }
}
