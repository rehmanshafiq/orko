import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, List<OnboardingItemEntity>>> getOnboardingItems();

  Future<Either<Failure, void>> completeOnboarding();
}
