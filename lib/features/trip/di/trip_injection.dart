import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/trip/data/datasources/remote/trip_remote_datasource.dart';
import 'package:orko_hubco/features/trip/data/datasources/remote/trip_remote_datasource_impl.dart';
import 'package:orko_hubco/features/trip/data/repositories/trip_repository_impl.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';
import 'package:orko_hubco/features/trip/domain/usecases/delete_saved_trip_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/get_saved_trip_detail_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/get_saved_trips_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/plan_trip_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/save_trip_usecase.dart';

void initTripDependencies() {
  // Data source
  sl.registerLazySingleton<TripRemoteDataSource>(
    () => TripRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<TripRepository>(
    () => TripRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => PlanTripUseCase(sl()));
  sl.registerLazySingleton(() => SaveTripUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedTripsUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedTripDetailUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSavedTripUseCase(sl()));
}
