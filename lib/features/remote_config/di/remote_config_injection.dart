import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/remote_config/data/datasources/remote/remote_config_datasource.dart';
import 'package:orko_hubco/features/remote_config/data/repositories/remote_config_repository_impl.dart';
import 'package:orko_hubco/features/remote_config/domain/repositories/remote_config_repository.dart';
import 'package:orko_hubco/features/remote_config/domain/usecases/fetch_remote_config_usecase.dart';
import 'package:orko_hubco/features/remote_config/presentation/cubit/remote_config_cubit.dart';

/// Registers all Remote Config feature dependencies.
void initRemoteConfigDependencies() {
  // Data Source
  sl.registerLazySingleton<RemoteConfigDataSource>(
    () => RemoteConfigDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<RemoteConfigRepository>(
    () => RemoteConfigRepositoryImpl(dataSource: sl()),
  );

  // Use Case
  sl.registerLazySingleton(() => FetchRemoteConfigUseCase(sl()));

  // Cubit
  sl.registerFactory(() => RemoteConfigCubit(fetchConfigUseCase: sl()));
}
