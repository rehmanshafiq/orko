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
        imagePath: AppImages.onboarding1,
        title: 'Charge Smarter.\nDrive Further.',
        description:
            'Discover EV charging stations across Pakistan - instantly.',
      ),
      OnboardingItemEntity(
        imagePath: AppImages.onboarding2,
        title: 'Find. Book. Charge.',
        description:
            'Real-time station availability, instant booking, and seamless navigation.',
      ),
      OnboardingItemEntity(
        imagePath: AppImages.onboarding3,
        title: 'Pay Your Way.\nEarn Rewards.',
        description:
            'Multiple payment options including Easypaisa, JazzCash, and cards. Earn green credits on every charge.',
      ),
    ];
  }

  @override
  Future<void> completeOnboarding() {
    return AppStorage.setOnboardingCompleted(true);
  }
}
