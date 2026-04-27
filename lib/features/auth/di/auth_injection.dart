import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource_impl.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource_impl.dart';
import 'package:orko_hubco/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/logout_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/register_usecase.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';

/// Registers all Auth feature dependencies.
void initAuthDependencies() {
  // ── Data Sources ──────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(storageService: sl()),
  );

  // ── Repository ────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // ── Use Cases ─────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // ── Cubit ─────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );
}
