import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/onboarding/data/datasources/local/onboarding_local_datasource.dart';
import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';
import 'package:orko_hubco/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({required OnboardingLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  final OnboardingLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, List<OnboardingItemEntity>>>
      getOnboardingItems() async {
    try {
      final items = await _localDataSource.getOnboardingItems();
      return Right(items);
    } catch (_) {
      return const Left(
        CacheFailure(message: 'Unable to load onboarding data.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> completeOnboarding() async {
    try {
      await _localDataSource.completeOnboarding();
      return const Right(null);
    } catch (_) {
      return const Left(
        CacheFailure(message: 'Unable to save onboarding status.'),
      );
    }
  }
}
