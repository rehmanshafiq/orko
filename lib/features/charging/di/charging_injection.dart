import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/charging/data/datasources/remote/charging_remote_datasource.dart';
import 'package:orko_hubco/features/charging/data/repositories/charging_repository_impl.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';
import 'package:orko_hubco/features/charging/domain/usecases/add_favourite_station_usecase.dart';
import 'package:orko_hubco/features/charging/domain/usecases/check_charger_compatibility_usecase.dart';
import 'package:orko_hubco/features/charging/domain/usecases/get_charging_station_detail_usecase.dart';
import 'package:orko_hubco/features/charging/domain/usecases/get_favourite_stations_usecase.dart';
import 'package:orko_hubco/features/charging/domain/usecases/remove_favourite_station_usecase.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_bloc.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_cubit.dart';

void initChargingDependencies() {
  // Data sources
  sl.registerLazySingleton<ChargingRemoteDataSource>(
    () => ChargingRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<ChargingRepository>(
    () => ChargingRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetChargingStationDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetFavouriteStationsUseCase(sl()));
  sl.registerLazySingleton(() => AddFavouriteStationUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFavouriteStationUseCase(sl()));
  sl.registerLazySingleton(() => CheckChargerCompatibilityUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => ChargingStationDetailBloc(
      getStationDetailUseCase: sl(),
      getFavouriteStationsUseCase: sl(),
      addFavouriteStationUseCase: sl(),
      removeFavouriteStationUseCase: sl(),
    ),
  );

  // Live charging-status cubit (new instance per screen). The live-session use
  // case is registered by initBookingDependencies(), which runs first.
  sl.registerFactory(
    () => ChargingStatusCubit(getLiveSessionUseCase: sl()),
  );
}
