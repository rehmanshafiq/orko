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
        imagePath: AppImages.onboardingCharging,
        title: 'Charging Every\n',
        titleHighlight: 'Journey',
        description: '',
      ),
    ];
  }

  @override
  Future<void> completeOnboarding() {
    return AppStorage.setOnboardingCompleted(true);
  }
}
