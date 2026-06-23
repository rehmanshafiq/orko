import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/google_auth_service.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource_impl.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource_impl.dart';
import 'package:orko_hubco/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';
import 'package:orko_hubco/features/auth/domain/usecases/get_user_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/logout_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/register_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/signup_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/verify_otp_usecase.dart';
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

  // ── Services ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());

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
  sl.registerLazySingleton(() => LoginWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => ResendOtpUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetUserUseCase(sl()));

  // ── Cubit ─────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      loginWithGoogleUseCase: sl(),
      registerUseCase: sl(),
      signUpUseCase: sl(),
      verifyOtpUseCase: sl(),
      resendOtpUseCase: sl(),
      logoutUseCase: sl(),
      googleAuthService: sl(),
      pushNotificationService: sl(),
    ),
  );
}
