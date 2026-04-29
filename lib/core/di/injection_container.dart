import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/features/auth/di/auth_injection.dart';
import 'package:orko_hubco/features/map/di/map_injection.dart';
import 'package:orko_hubco/features/onboarding/di/onboarding_injection.dart';
import 'package:orko_hubco/features/profile/di/profile_injection.dart';
import 'package:orko_hubco/features/remote_config/di/remote_config_injection.dart';

final sl = GetIt.instance;

/// Initializes all dependencies.
/// Call this in main() before runApp().
Future<void> initDependencies() async {
  // ── Core ──────────────────────────────────────────────────────────────

  // Network
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Services
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // ── Features ──────────────────────────────────────────────────────────

  initAuthDependencies();
  initMapDependencies();
  initOnboardingDependencies();
  initProfileDependencies();
  initRemoteConfigDependencies();
}
