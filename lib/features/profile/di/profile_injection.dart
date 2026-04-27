import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:orko_hubco/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:orko_hubco/features/profile/domain/repositories/profile_repository.dart';
import 'package:orko_hubco/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';

/// Registers all Profile feature dependencies.
void initProfileDependencies() {
  // Data Sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));

  // Cubit
  sl.registerFactory(() => ProfileCubit(getProfileUseCase: sl()));
}
