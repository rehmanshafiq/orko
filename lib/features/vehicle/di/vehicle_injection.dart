import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/vehicle/data/datasources/remote/vehicle_remote_datasource.dart';
import 'package:orko_hubco/features/vehicle/data/datasources/remote/vehicle_remote_datasource_impl.dart';
import 'package:orko_hubco/features/vehicle/data/repositories/vehicle_repository_impl.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/add_vehicle_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/create_custom_make_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/create_custom_model_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/delete_vehicle_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_user_vehicles_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_vehicle_makes_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_vehicle_models_usecase.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_cubit.dart';

void initVehicleDependencies() {
  // Data source
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetVehicleMakesUseCase(sl()));
  sl.registerLazySingleton(() => GetVehicleModelsUseCase(sl()));
  sl.registerLazySingleton(() => AddVehicleUseCase(sl()));
  sl.registerLazySingleton(() => GetUserVehiclesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteVehicleUseCase(sl()));
  sl.registerLazySingleton(() => CreateCustomMakeUseCase(sl()));
  sl.registerLazySingleton(() => CreateCustomModelUseCase(sl()));

  // Cubit (new instance per profile screen).
  sl.registerFactory(
    () => VehicleCubit(
      getMakesUseCase: sl(),
      getModelsUseCase: sl(),
      addVehicleUseCase: sl(),
      getUserVehiclesUseCase: sl(),
      deleteVehicleUseCase: sl(),
      createCustomMakeUseCase: sl(),
      createCustomModelUseCase: sl(),
    ),
  );
}
