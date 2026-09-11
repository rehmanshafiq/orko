import 'dart:convert';

// import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:get_storage/get_storage.dart';
// import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';

/// Singleton that resolves [RemoteConfigModel] without blocking app launch.
///
/// TEMP: Firebase Remote Config fetch is commented out. Config is loaded only
/// from the bundled [assets/data/remote_config.json]. Re-enable the Firebase
/// paths below when server-driven config is needed again.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  /// Firebase Remote Config parameter that holds the inner `api_constants`
  /// object as a JSON string.
  // static const String _firebaseKey = 'api_constants';

  /// Bundled default — currently the only config source.
  static const String _assetPath = 'assets/data/remote_config.json';

  /// Live config for the session. Datasources read this via [config].
  static RemoteConfigModel? config;

  // final GetStorage _storage = GetStorage();
  // FirebaseRemoteConfig? _remoteConfig;
  // bool _backgroundRefreshInFlight = false;

  /// Resolves config for startup (or a forced refresh).
  ///
  /// Currently always loads from [assets/data/remote_config.json].
  Future<RemoteConfigModel> initialize({bool forceRefresh = false}) async {
    if (config != null && !forceRefresh) {
      return config!;
    }

    // ── Local-only: always use the bundled asset ─────────────────────────
    final fromAsset = await _readFromAsset();
    if (fromAsset != null) {
      config = fromAsset;
      AppLogger.d(
        '[RemoteConfig] Using bundled asset only '
        '(Firebase fetch commented out)',
      );
      // unawaited(_refreshFromFirebaseInBackground());
      return fromAsset;
    }

    // // ── Forced refresh / Firebase path (disabled) ───────────────────────
    // final fromFirebase = await _fetchFromFirebase();
    // if (fromFirebase != null) {
    //   config = fromFirebase;
    //   return fromFirebase;
    // }
    //
    // final localFallback = await _resolveLocalConfig();
    // if (localFallback != null) {
    //   config = localFallback;
    //   return localFallback;
    // }

    throw StateError(
      'RemoteConfigService: failed to load assets/data/remote_config.json.',
    );
  }

  // /// Cache first, then bundled [assets/data/remote_config.json].
  // Future<RemoteConfigModel?> _resolveLocalConfig() async {
  //   final fromCache = _readFromCache();
  //   if (fromCache != null) return fromCache;
  //
  //   final fromAsset = await _readFromAsset();
  //   if (fromAsset != null) {
  //     _writeToCache(fromAsset);
  //     AppLogger.d(
  //       '[RemoteConfig] Seeded cache from assets/data/remote_config.json',
  //     );
  //     return fromAsset;
  //   }
  //   return null;
  // }

  // /// Fetches Firebase after a local config is already active, then swaps it in.
  // Future<void> _refreshFromFirebaseInBackground() async {
  //   if (_backgroundRefreshInFlight) return;
  //   _backgroundRefreshInFlight = true;
  //   try {
  //     final fromFirebase = await _fetchFromFirebase();
  //     if (fromFirebase == null) {
  //       AppLogger.d(
  //         '[RemoteConfig] Background fetch returned nothing; '
  //         'keeping local/asset config',
  //       );
  //       return;
  //     }
  //     config = fromFirebase;
  //     AppLogger.d('[RemoteConfig] In-memory config updated from server');
  //   } finally {
  //     _backgroundRefreshInFlight = false;
  //   }
  // }

  // // ── Firebase ────────────────────────────────────────────────────────────
  //
  // Future<RemoteConfigModel?> _fetchFromFirebase() async {
  //   try {
  //     final remoteConfig = _remoteConfig ??= FirebaseRemoteConfig.instance;
  //
  //     await remoteConfig.setConfigSettings(
  //       RemoteConfigSettings(
  //         fetchTimeout: const Duration(seconds: 15),
  //         minimumFetchInterval:
  //             kReleaseMode ? const Duration(hours: 1) : Duration.zero,
  //       ),
  //     );
  //
  //     await _seedFirebaseDefaults(remoteConfig);
  //
  //     final activated = await remoteConfig.fetchAndActivate();
  //     AppLogger.d('[RemoteConfig] fetchAndActivate() → activated: $activated');
  //
  //     final raw = remoteConfig.getString(_firebaseKey);
  //     AppLogger.d(
  //       '[RemoteConfig] Firebase raw response for "$_firebaseKey": $raw',
  //     );
  //
  //     if (raw.trim().isEmpty) {
  //       AppLogger.d('[RemoteConfig] Firebase key "$_firebaseKey" is empty.');
  //       return null;
  //     }
  //
  //     final decoded = jsonDecode(raw);
  //     if (decoded is! Map) {
  //       AppLogger.d('[RemoteConfig] Firebase value is not a JSON object.');
  //       return null;
  //     }
  //
  //     final model = RemoteConfigModel(
  //       apiConstants: ApiConstants.fromJson(
  //         Map<String, dynamic>.from(decoded),
  //       ),
  //     );
  //
  //     _writeToCache(model);
  //     AppLogger.d('[RemoteConfig] Loaded from Firebase Remote Config');
  //     return model;
  //   } catch (error, stackTrace) {
  //     AppLogger.d('[RemoteConfig] Firebase fetch failed: $error\n$stackTrace');
  //     return null;
  //   }
  // }
  //
  // Future<void> _seedFirebaseDefaults(FirebaseRemoteConfig remoteConfig) async {
  //   try {
  //     final raw = await rootBundle.loadString(_assetPath);
  //     final decoded = jsonDecode(raw);
  //     if (decoded is! Map) return;
  //
  //     final apiConstants = decoded['api_constants'];
  //     if (apiConstants is! Map) return;
  //
  //     await remoteConfig.setDefaults(<String, dynamic>{
  //       _firebaseKey: jsonEncode(Map<String, dynamic>.from(apiConstants)),
  //     });
  //   } catch (error) {
  //     AppLogger.d('[RemoteConfig] Failed to seed Firebase defaults: $error');
  //   }
  // }

  // // ── GetStorage cache ────────────────────────────────────────────────────
  //
  // RemoteConfigModel? _readFromCache() {
  //   try {
  //     final raw = _storage.read<String>(StorageConstants.remoteConfigCache);
  //     if (raw == null || raw.trim().isEmpty) {
  //       return null;
  //     }
  //
  //     final decoded = jsonDecode(raw);
  //     if (decoded is! Map) {
  //       return null;
  //     }
  //
  //     AppLogger.d('[RemoteConfig] Loaded from GetStorage cache.');
  //     return RemoteConfigModel.fromJson(Map<String, dynamic>.from(decoded));
  //   } catch (error) {
  //     AppLogger.d('[RemoteConfig] Cache read failed: $error');
  //     return null;
  //   }
  // }
  //
  // void _writeToCache(RemoteConfigModel model) {
  //   try {
  //     _storage.write(
  //       StorageConstants.remoteConfigCache,
  //       jsonEncode(model.toJson()),
  //     );
  //   } catch (error) {
  //     AppLogger.d('[RemoteConfig] Cache write failed: $error');
  //   }
  // }

  // ── Bundled asset ───────────────────────────────────────────────────────

  Future<RemoteConfigModel?> _readFromAsset() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      AppLogger.d(
        '[RemoteConfig] Loaded from bundled asset ($_assetPath).',
      );
      return RemoteConfigModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      AppLogger.d('[RemoteConfig] Asset read failed: $error');
      return null;
    }
  }
}
