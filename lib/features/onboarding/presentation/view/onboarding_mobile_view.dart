import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_routing/app_navigations.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingMobileView extends StatefulWidget {
  const OnboardingMobileView({super.key});

  @override
  State<OnboardingMobileView> createState() => _OnboardingMobileViewState();
}

class _OnboardingMobileViewState extends State<OnboardingMobileView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onSkipOrGetStarted(BuildContext context) async {
    await context.read<OnboardingCubit>().complete();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: BlocConsumer<OnboardingCubit, OnboardingState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(state.errorMessage!)),
              );
            }

            if (state.isCompleted) {
              AppNavigations.navigateToRegister(context);
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.items.isEmpty) {
              return Center(
                child: AppText(
                  'No onboarding data found',
                  color: AppColors.whiteColor.withValues(alpha: 0.7),
                ),
              );
            }

            return Padding(
              padding: AppUtils.horizontal20Padding,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Visibility(
                      visible: !state.isLastPage,
                      maintainAnimation: true,
                      maintainState: true,
                      maintainSize: true,
                      child: TextButton(
                        onPressed:
                            state.isCompleting
                                ? null
                                : () => _onSkipOrGetStarted(context),
                        child: AppText(
                          'Skip',
                          color: AppColors.whiteColor.withValues(alpha: 0.7),
                          fontSize: FontSizes.font15Sp,
                          fontWeight: FontWeights.weight500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: state.items.length,
                      onPageChanged:
                          context.read<OnboardingCubit>().setCurrentIndex,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return _OnboardingSlide(
                          item: item,
                          imageHeight: screenHeight * 0.42,
                        );
                      },
                    ),
                  ),
                  12.verticalSpace,
                  _PageIndicator(
                    count: state.items.length,
                    activeIndex: state.currentIndex,
                  ),
                  18.verticalSpace,
                  if (state.isLastPage)
                    PrimaryButtonWidget(
                      text: 'Get Started',
                      buttonHeight: 56.h,
                      buttonColor: AppColors.primaryLightColor,
                      textColor: AppColors.whiteColor,
                      fontSize: FontSizes.font16Sp,
                      fontWeight: FontWeights.weight600,
                      isEnabled: !state.isCompleting,
                      onPress:
                          state.isCompleting
                              ? null
                              : () => _onSkipOrGetStarted(context),
                    )
                  else
                    56.verticalSpace,
                  12.verticalSpace,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.item,
    required this.imageHeight,
  });

  final OnboardingItemEntity item;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AppPngImageView(
            appImagePath: item.imagePath,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ),
        28.verticalSpace,
        AppText(
          item.title,
          textAlign: TextAlign.center,
          color: AppColors.whiteColor,
          fontSize: FontSizes.font30Sp,
          fontWeight: FontWeight.bold,
        ),
        14.verticalSpace,
        AppText(
          item.description,
          textAlign: TextAlign.center,
          color: AppColors.whiteColor.withValues(alpha: 0.6),
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight400,
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == activeIndex
                ? AppColors.primaryLightColor
                : AppColors.whiteColor.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
