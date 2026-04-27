import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';

abstract class OnboardingLocalDataSource {
  Future<List<OnboardingItemEntity>> getOnboardingItems();

  Future<void> completeOnboarding();
}
