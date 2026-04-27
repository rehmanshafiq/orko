import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/onboarding/data/datasources/local/onboarding_local_datasource.dart';
import 'package:orko_hubco/features/onboarding/data/datasources/local/onboarding_local_datasource_impl.dart';
import 'package:orko_hubco/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:orko_hubco/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:orko_hubco/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:orko_hubco/features/onboarding/domain/usecases/get_onboarding_items_usecase.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_cubit.dart';

void initOnboardingDependencies() {
  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => const OnboardingLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetOnboardingItemsUseCase(sl()));
  sl.registerLazySingleton(() => CompleteOnboardingUseCase(sl()));

  sl.registerFactory(
    () => OnboardingCubit(
      getOnboardingItemsUseCase: sl(),
      completeOnboardingUseCase: sl(),
    ),
  );
}
