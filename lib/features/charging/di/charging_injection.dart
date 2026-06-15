import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/charging/data/datasources/remote/charging_remote_datasource.dart';
import 'package:orko_hubco/features/charging/data/repositories/charging_repository_impl.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';
import 'package:orko_hubco/features/charging/domain/usecases/get_charging_station_detail_usecase.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_bloc.dart';

void initChargingDependencies() {
  // Data sources
  sl.registerLazySingleton<ChargingRemoteDataSource>(
    () => ChargingRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<ChargingRepository>(
    () => ChargingRepositoryImpl(remoteDataSource: sl()),
  );

  // Use case
  sl.registerLazySingleton(() => GetChargingStationDetailUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => ChargingStationDetailBloc(getStationDetailUseCase: sl()),
  );
}
