import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/onboarding/data/datasources/local/onboarding_local_datasource.dart';
import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl();

  @override
  Future<List<OnboardingItemEntity>> getOnboardingItems() async {
    return [
      OnboardingItemEntity(
        imagePath: AppImages.onboardingLocateCharger,
        title: 'Locate a ',
        titleHighlight: 'Charger',
        description: 'See live availability near you.',
      ),
      OnboardingItemEntity(
        imagePath: AppImages.onboardingBookSession,
        title: 'Book Your Charging\n',
        titleHighlight: 'Session',
        description: 'Reserve a slot in seconds.',
      ),
      OnboardingItemEntity(
        imagePath: AppImages.onboardingPaySecurely,
        title: 'Pay Securely with ',
        titleHighlight: 'Ease',
        description: 'Fast, secure in-app payments.',
      ),
    ];
  }

  @override
  Future<void> completeOnboarding() {
    return AppStorage.setOnboardingCompleted(true);
  }
}
