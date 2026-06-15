import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/remote_config/presentation/bloc/remote_config_bloc.dart';

/// Registers all Remote Config feature dependencies.
void initRemoteConfigDependencies() {
  // Service (singleton, holds in-memory config cache)
  sl.registerLazySingleton<RemoteConfigService>(
    () => RemoteConfigService.instance,
  );

  // Bloc
  sl.registerFactory(() => RemoteConfigBloc(service: sl()));
}
