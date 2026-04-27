import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';
import 'package:orko_hubco/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingItemsUseCase
    implements UseCase<List<OnboardingItemEntity>, NoParams> {
  GetOnboardingItemsUseCase(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, List<OnboardingItemEntity>>> call(
    NoParams params,
  ) async {
    return _repository.getOnboardingItems();
  }
}
