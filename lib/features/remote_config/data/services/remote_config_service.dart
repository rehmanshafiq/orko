import 'dart:convert';
import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';

/// Singleton service that resolves the app's [RemoteConfigModel] using a strict
/// multi-layer fallback strategy:
///
/// 1. Firebase Remote Config (`fetchAndActivate`)  → persisted to GetStorage.
/// 2. GetStorage cache (`remote_config_cache`)     → last known good value.
/// 3. Bundled asset (`assets/data/remote_config.json`) → guaranteed default.
///
/// The service never throws for transient failures of an individual layer; it
/// only fails if EVERY layer fails. The last successfully resolved config is
/// kept in memory for the lifetime of the session.
class RemoteConfigService {
  RemoteConfigService._();

  /// Shared singleton instance.
  static final RemoteConfigService instance = RemoteConfigService._();

  /// Firebase Remote Config parameter key holding the inner `api_constants`
  /// object as a JSON string.
  static const String _firebaseKey = 'api_constants';

  /// Bundled fallback asset path.
  static const String _assetPath = 'assets/data/remote_config.json';

  /// In-memory cache, exposed via the static [config] accessor.
  static RemoteConfigModel? config;

  final GetStorage _storage = GetStorage();
  FirebaseRemoteConfig? _remoteConfig;

  /// Resolves the configuration following the strict fallback order.
  ///
  /// Returns the cached in-memory config on subsequent calls within the same
  /// session unless [forceRefresh] is `true`, avoiding redundant Firebase
  /// fetches.
  ///
  /// Throws [StateError] only when ALL fallback layers fail.
  Future<RemoteConfigModel> initialize({bool forceRefresh = false}) async {
    if (config != null && !forceRefresh) {
      return config!;
    }

    // ── Step 1: Firebase Remote Config ──────────────────────────────────
    final fromFirebase = await _fetchFromFirebase();
    if (fromFirebase != null) {
      config = fromFirebase;
      return fromFirebase;
    }

    // ── Step 2: GetStorage cache ────────────────────────────────────────
    final fromCache = _readFromCache();
    if (fromCache != null) {
      config = fromCache;
      return fromCache;
    }

    // ── Step 3: Bundled asset (last resort) ─────────────────────────────
    final fromAsset = await _readFromAsset();
    if (fromAsset != null) {
      config = fromAsset;
      return fromAsset;
    }

    throw StateError(
      'RemoteConfigService: all fallback layers failed to resolve config.',
    );
  }

  // ── Layer 1 ───────────────────────────────────────────────────────────

  Future<RemoteConfigModel?> _fetchFromFirebase() async {
    try {
      final remoteConfig = _remoteConfig ??= FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval:
              kReleaseMode ? const Duration(hours: 1) : Duration.zero,
        ),
      );

      final activated = await remoteConfig.fetchAndActivate();
      AppLogger.d('[RemoteConfig] fetchAndActivate() → activated: $activated');

      final raw = remoteConfig.getString(_firebaseKey);
      AppLogger.d('[RemoteConfig] Firebase raw response for "$_firebaseKey": $raw');

      if (raw.trim().isEmpty) {
        AppLogger.d('[RemoteConfig] Firebase key "$_firebaseKey" is empty.');
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        AppLogger.d('[RemoteConfig] Firebase value is not a JSON object.');
        return null;
      }

      // Firebase stores the inner `api_constants` object directly.
      final model = RemoteConfigModel(
        apiConstants: ApiConstants.fromJson(Map<String, dynamic>.from(decoded)),
      );

      _writeToCache(model);
      AppLogger.d('[RemoteConfig] Loaded from Firebase Remote Config');
      return model;
    } catch (error, stackTrace) {
      AppLogger.d('[RemoteConfig] Firebase fetch failed: $error\n$stackTrace');
      return null;
    }
  }

  // ── Layer 2 ───────────────────────────────────────────────────────────

  RemoteConfigModel? _readFromCache() {
    try {
      final raw = _storage.read<String>(StorageConstants.remoteConfigCache);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      AppLogger.d('[RemoteConfig] Loaded from GetStorage cache.');
      return RemoteConfigModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      AppLogger.d('[RemoteConfig] Cache read failed: $error');
      return null;
    }
  }

  void _writeToCache(RemoteConfigModel model) {
    try {
      _storage.write(
        StorageConstants.remoteConfigCache,
        jsonEncode(model.toJson()),
      );
    } catch (error) {
      AppLogger.d('[RemoteConfig] Cache write failed: $error');
    }
  }

  // ── Layer 3 ───────────────────────────────────────────────────────────

  Future<RemoteConfigModel?> _readFromAsset() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      AppLogger.d('[RemoteConfig] Loaded from bundled asset.');
      return RemoteConfigModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      AppLogger.d('[RemoteConfig] Asset read failed: $error');
      return null;
    }
  }
}
