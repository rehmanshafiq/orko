import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/app_store_constants.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/core/network/interceptors/error_interceptor.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Holds the app-update state reported by the backend's `update_available`
/// flag (fed by `AppUpdateInterceptor`) and exposes it as notifiers for the
/// router and the update prompts.
///
/// * [forceUpdate] — the blocking update screen must be shown. Persisted per
///   app version so it is restored on a cold start; cleared when the backend
///   answers `0` or the app version changes (i.e. the user updated).
/// * [softUpdatePending] — an optional update prompt is waiting to be shown.
///   It is raised at most once per app session and never while a force update
///   is active.
///
/// Also re-checks the flag on app start and resume with a silent request.
class AppUpdateService with WidgetsBindingObserver {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  final ValueNotifier<bool> forceUpdate = ValueNotifier<bool>(false);
  final ValueNotifier<bool> softUpdatePending = ValueNotifier<bool>(false);

  /// Minimum gap between two re-check requests (resume can fire repeatedly).
  static const Duration _recheckCooldown = Duration(seconds: 15);

  /// Bundled fallback when Remote Config omits the endpoint.
  static const String _recheckFallbackEndpoint =
      'api/v1/charging-station/filter-options/';

  final GetStorage _box = GetStorage();
  String? _appVersion;
  bool _softShownThisSession = false;
  bool _initialized = false;
  DateTime? _lastRecheckAt;

  /// Resolves the app version, restores a force update recorded for it and
  /// starts listening for app resume. Call once before `runApp`.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _appVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // Unknown version: nothing is persisted or restored this session.
    }

    final storedVersion =
        _box.read<String>(StorageConstants.forceUpdateVersion);
    if (storedVersion != null) {
      if (_appVersion != null && storedVersion == _appVersion) {
        forceUpdate.value = true;
      } else {
        // Recorded for an older version — the user has since updated.
        _box.remove(StorageConstants.forceUpdateVersion);
      }
    }

    WidgetsBinding.instance.addObserver(this);
  }

  /// Applies an `update_available` level from any API response.
  ///
  /// Many responses arrive concurrently, so this is idempotent: notifiers only
  /// change on a real state change, a soft update never downgrades an active
  /// force update, and a soft prompt is raised once per session.
  void handleLevel(int level) {
    switch (level) {
      case 2:
        softUpdatePending.value = false;
        if (_appVersion != null) {
          _box.write(StorageConstants.forceUpdateVersion, _appVersion);
        }
        forceUpdate.value = true;
      case 1:
        if (forceUpdate.value || _softShownThisSession) return;
        softUpdatePending.value = true;
      case 0:
        // The backend no longer requires an update for this version.
        softUpdatePending.value = false;
        if (forceUpdate.value) {
          _box.remove(StorageConstants.forceUpdateVersion);
          forceUpdate.value = false;
        }
    }
  }

  /// Marks the soft prompt as shown, so it isn't raised again this session.
  void markSoftUpdateShown() {
    _softShownThisSession = true;
    softUpdatePending.value = false;
  }

  /// Fires a silent, lightweight request purely so its `update_available`
  /// flag refreshes the state (e.g. a version blocked or unblocked meanwhile).
  /// Throttled, never throws and never toasts.
  Future<void> recheck() async {
    final now = DateTime.now();
    if (_lastRecheckAt != null &&
        now.difference(_lastRecheckAt!) < _recheckCooldown) {
      return;
    }
    _lastRecheckAt = now;

    if (!sl.isRegistered<ApiClient>()) return;
    try {
      final configured = RemoteConfigService.config?.apiConstants.apiEndpoints
          .chargingStationFilterOptions
          .trim();
      final endpoint = (configured == null || configured.isEmpty)
          ? _recheckFallbackEndpoint
          : configured;
      await sl<ApiClient>().get(
        endpoint,
        options: Options(extra: {ErrorInterceptor.silentKey: true}),
      );
    } catch (_) {
      // Offline or failing: keep the current state.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) recheck();
  }

  /// Opens this app's store listing: the Remote Config URL (`play_store_url` /
  /// `app_store_url`) first, then the bundled store-app and web links.
  /// Returns `false` when none could be opened.
  Future<bool> openStore() async {
    final constants = RemoteConfigService.config?.apiConstants;
    final configured = _storeUri(
      _isIOS ? constants?.appStoreUrl : constants?.playStoreUrl,
    );
    final uris = [
      if (configured != null) configured,
      ...(_isIOS
          ? [AppStoreConstants.appStoreAppUri, AppStoreConstants.appStoreWebUri]
          : [
              AppStoreConstants.playStoreAppUri,
              AppStoreConstants.playStoreWebUri,
            ]),
    ];
    for (final uri in uris) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // Try the next link.
      }
    }
    return false;
  }

  /// A configured store URL, or `null` when empty or not an https link (a
  /// remote value must not launch arbitrary schemes).
  static Uri? _storeUri(String? url) {
    final uri = Uri.tryParse(url?.trim() ?? '');
    if (uri == null || uri.scheme.toLowerCase() != 'https' || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  /// Name of the store for this platform, for user-facing copy.
  String get storeName => _isIOS ? 'App Store' : 'Play Store';

  bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}
