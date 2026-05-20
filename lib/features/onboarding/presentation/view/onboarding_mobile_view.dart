import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_revamped_theme.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_routing/app_navigations.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
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

  void _goToNextPage(BuildContext context, OnboardingState state) {
    if (state.isCompleting) return;

    if (state.isLastPage) {
      _onSkipOrGetStarted(context);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage(OnboardingState state) {
    if (state.currentIndex == 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppRevampedTheme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.onboardingBackgroundTop,
              t.onboardingBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
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
                    color: t.textSecondary,
                  ),
                );
              }

              return Padding(
                padding: AppUtils.horizontal20Padding,
                child: Column(
                  children: [
                    _buildHeader(context, t, state),
                    20.verticalSpace,
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: state.items.length,
                        onPageChanged:
                            context.read<OnboardingCubit>().setCurrentIndex,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _OnboardingSlide(
                            t: t,
                            item: item,
                            imageHeight: screenHeight * 0.36,
                          );
                        },
                      ),
                    ),
                    24.verticalSpace,
                    _PageIndicator(
                      t: t,
                      count: state.items.length,
                      activeIndex: state.currentIndex,
                    ),
                    28.verticalSpace,
                    _buildBottomActions(context, t, state),
                    16.verticalSpace,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppRevampedTheme t,
    OnboardingState state,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          'HUBCO',
          color: t.brandGreen,
          fontSize: FontSizes.font22Sp,
          fontWeight: FontWeights.weight700,
          letterSpacing: 0.6,
        ),
        TextButton(
          onPressed:
              state.isCompleting ? null : () => _onSkipOrGetStarted(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: AppText(
            'SKIP',
            color: t.onboardingSkipText,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    AppRevampedTheme t,
    OnboardingState state,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _BackButton(
            t: t,
            onPressed: state.currentIndex == 0
                ? null
                : () => _goToPreviousPage(state),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          flex: 6,
          child: _NextButton(
            t: t,
            label: state.isLastPage ? 'Get Started' : 'Next',
            isEnabled: !state.isCompleting,
            onPressed: () => _goToNextPage(context, state),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.t,
    required this.item,
    required this.imageHeight,
  });

  final AppRevampedTheme t;
  final OnboardingItemEntity item;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final titleLines = item.title.split('\n');
    final primaryTitle = titleLines.first;
    final accentTitle = titleLines.length > 1 ? titleLines.sublist(1).join('\n') : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          _HeroImage(t: t, imagePath: item.imagePath, height: imageHeight),
          32.verticalSpace,
          Column(
            children: [
              AppText(
                primaryTitle,
                textAlign: TextAlign.center,
                color: t.textPrimary,
                fontSize: FontSizes.font32Sp,
                fontWeight: FontWeights.weight700,
                height: 1.15,
              ),
              if (accentTitle != null)
                Text(
                  accentTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.brandGreen,
                    fontSize: FontSizes.font32Sp,
                    fontWeight: FontWeights.weight700,
                    fontStyle: FontStyle.italic,
                    height: 1.15,
                    fontFamily: AppFonts.lexend,
                  ),
                ),
            ],
          ),
          18.verticalSpace,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: AppText(
              item.description,
              textAlign: TextAlign.center,
              color: t.textSecondary,
              fontSize: FontSizes.font16Sp,
              fontWeight: FontWeights.weight400,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.t,
    required this.imagePath,
    required this.height,
  });

  final AppRevampedTheme t;
  final String imagePath;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: t.brandGreen.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: AppPngImageView(
          appImagePath: imagePath,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.t,
    required this.count,
    required this.activeIndex,
  });

  final AppRevampedTheme t;
  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: index == activeIndex ? 28.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: index == activeIndex
                ? t.brandGreen
                : t.indicatorInactive,
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.t, required this.onPressed});

  final AppRevampedTheme t;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: t.onboardingBackButtonBackground,
          disabledBackgroundColor:
              t.onboardingBackButtonBackground.withValues(alpha: 0.65),
          foregroundColor: t.textPrimary,
          disabledForegroundColor: t.textPrimary.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: AppText(
          'Back',
          color: onPressed == null
              ? t.textPrimary.withValues(alpha: 0.35)
              : t.textPrimary,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight600,
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.t,
    required this.label,
    required this.onPressed,
    required this.isEnabled,
  });

  final AppRevampedTheme t;
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [
                    t.brandGreen,
                    t.brandGreenLight,
                  ]
                : [
                    t.disabledButtonGrey,
                    t.disabledButtonGrey,
                  ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: t.brandGreen.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: AppColors.transparentColor,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(999),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  label,
                  color: AppColors.whiteColor,
                  fontSize: FontSizes.font16Sp,
                  fontWeight: FontWeights.weight600,
                ),
                8.horizontalSpace,
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.whiteColor,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
