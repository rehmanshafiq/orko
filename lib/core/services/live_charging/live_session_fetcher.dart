import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/core/network/certificate_pinning.dart';
import 'package:orko_hubco/core/services/secure_store.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';
import 'package:orko_hubco/features/booking/data/models/live_session_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/firebase_options.dart';

/// Fetches the current live charging session in a way that works from *any*
/// isolate — including the foreground-service background isolate, which starts
/// with none of the app's singletons (GetStorage / SecureStore / RemoteConfig /
/// GetIt) initialised.
///
/// It reuses the app's [ApiClient] (Dio + auth / app-header interceptors + cert
/// pinning) and [LiveSessionModel] so the request is byte-for-byte the same as
/// everywhere else in the app. Every bootstrap step is idempotent, so this is
/// equally safe to use on the main isolate (where the singletons already exist).
class LiveSessionFetcher {
  LiveSessionFetcher();

  ApiClient? _client;
  bool _bootstrapped = false;

  /// Re-initialises the minimal stack the request needs, exactly once.
  Future<void> _bootstrap() async {
    if (_bootstrapped) return;

    // GetStorage backs RemoteConfig's cache layer and SecureStore's migration.
    await GetStorage.init();

    // Firebase is required for the Remote Config layer; tolerate an already-
    // initialised app (the FCM background isolate may have done it first).
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Already initialised in this isolate — ignore.
    }

    // Resolves the base URL + live-session endpoint (Firebase → cache → asset).
    // Never fatal: ApiClient.baseUrl still has a compile-time fallback.
    try {
      await RemoteConfigService.instance.initialize();
    } catch (e) {
      AppLogger.d('[LiveFetch] remote config init failed: $e');
    }

    // Loads the encrypted token mirror the AuthInterceptor reads synchronously.
    await SecureStore.instance.init();

    // Pinned CA bundle (no-op in debug); must precede ApiClient so the pinned
    // adapter is wired into Dio.
    await CertificatePinning.load();

    _client = ApiClient();
    _bootstrapped = true;
  }

  /// Returns the current live session, or `null` on any failure (network,
  /// auth, config). Never throws — the caller decides what to render on null.
  Future<LiveSessionModel?> fetch() async {
    try {
      await _bootstrap();

      final url = _liveSessionUrl();
      if (url == null) {
        AppLogger.d('[LiveFetch] no live-session endpoint configured');
        return null;
      }

      final response = await _client!.get(url);
      final data = response.data;

      // Success envelope is `{status, body:{active:...}}`.
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['body'] is Map) {
        return LiveSessionModel.fromJson(
          Map<String, dynamic>.from(data['body'] as Map),
        );
      }

      // A well-formed success always carries the body object; anything else
      // means there is no session running.
      return const LiveSessionModel(active: false);
    } catch (e) {
      AppLogger.d('[LiveFetch] fetch failed: $e');
      return null;
    }
  }

  /// Builds the live-session URL from Remote Config, mirroring the booking
  /// datasource's join (trailing slash preserved — Django needs it).
  String? _liveSessionUrl() {
    final endpoint = RemoteConfigService
        .config?.apiConstants.apiEndpoints.liveSession
        .trim();
    if (endpoint == null || endpoint.isEmpty) return null;

    final rawBase = ApiClient.baseUrl;
    final base =
        rawBase.endsWith('/') ? rawBase.substring(0, rawBase.length - 1) : rawBase;
    var path = endpoint;
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
  }
}
