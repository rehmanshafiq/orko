import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/map/data/datasources/remote/map_remote_datasource.dart';
import 'package:orko_hubco/features/map/data/repositories/map_repository_impl.dart';
import 'package:orko_hubco/features/map/domain/repositories/map_repository.dart';
import 'package:orko_hubco/features/map/domain/usecases/get_hubco_locations_usecase.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';

void initMapDependencies() {
  // Data source
  sl.registerLazySingleton<MapRemoteDataSource>(
    () => MapRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use case
  sl.registerLazySingleton(() => GetHubcoLocationsUseCase(sl()));

  // Cubit
  sl.registerFactory(() => MapCubit(getHubcoLocationsUseCase: sl()));
}
