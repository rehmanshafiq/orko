import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/onboarding/domain/repositories/onboarding_repository.dart';

class CompleteOnboardingUseCase implements UseCase<void, NoParams> {
  CompleteOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return _repository.completeOnboarding();
  }
}
