import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/utils/app_routing/app_navigations.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingMobileView extends StatelessWidget {
  const OnboardingMobileView({super.key});

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
                SnackBar(content: Text(state.errorMessage!)),
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
              return const Center(
                child: Text(
                  'No onboarding data found',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  if (!state.isLastPage)
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed:
                            state.isCompleting
                                ? null
                                : () => _onSkipOrGetStarted(context),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (state.isLastPage) 8.verticalSpace,
                  Expanded(
                    child: PageView.builder(
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
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF29E6B2), Color(0xFF1DBA97)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed:
                              state.isCompleting
                                  ? null
                                  : () => _onSkipOrGetStarted(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: state.isCompleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
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
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 46 / 2,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
        14.verticalSpace,
        Text(
          item.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18 / 2,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
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
                ? const Color(0xFF29E6B2)
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
