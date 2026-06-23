import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/search/data/datasources/local/search_local_datasource.dart';
import 'package:orko_hubco/features/search/data/datasources/remote/search_remote_datasource.dart';
import 'package:orko_hubco/features/search/data/repositories/search_repository_impl.dart';
import 'package:orko_hubco/features/search/domain/repositories/search_repository.dart';
import 'package:orko_hubco/features/search/domain/usecases/add_recent_search_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/clear_recent_searches_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/get_popular_stations_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/get_recent_searches_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/remove_recent_search_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/search_stations_usecase.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_cubit.dart';

void initSearchDependencies() {
  // Data sources
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<SearchLocalDataSource>(
    () => SearchLocalDataSourceImpl(storageService: sl()),
  );

  // Repository
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SearchStationsUseCase(sl()));
  sl.registerLazySingleton(() => GetPopularStationsUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentSearchesUseCase(sl()));
  sl.registerLazySingleton(() => AddRecentSearchUseCase(sl()));
  sl.registerLazySingleton(() => RemoveRecentSearchUseCase(sl()));
  sl.registerLazySingleton(() => ClearRecentSearchesUseCase(sl()));

  // Cubit
  sl.registerFactory(
    () => SearchCubit(
      searchStationsUseCase: sl(),
      getPopularStationsUseCase: sl(),
      getRecentSearchesUseCase: sl(),
      addRecentSearchUseCase: sl(),
      removeRecentSearchUseCase: sl(),
      clearRecentSearchesUseCase: sl(),
    ),
  );
}
