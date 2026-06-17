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

class _OnboardingMobileViewState extends State<OnboardingMobileView>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  /// Current page as a continuous double for swipe-linked animations. Falls
  /// back to [fallback] before the PageView has been laid out.
  double _pageOffset(double fallback) {
    if (_pageController.hasClients &&
        _pageController.position.haveDimensions) {
      return _pageController.page ?? fallback;
    }
    return fallback;
  }

  Future<void> _onSkipOrGetStarted(BuildContext context) async {
    await context.read<OnboardingCubit>().complete();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
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
                  color: ui.textMuted,
                ),
              );
            }

            return FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: Padding(
                  padding: AppUtils.horizontal20Padding,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed:
                              state.isCompleting
                                  ? null
                                  : () => _onSkipOrGetStarted(context),
                          child: AppText(
                            'Skip',
                            color: ui.textPrimary,
                            fontSize: FontSizes.font16Sp,
                            fontWeight: FontWeights.weight500,
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
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, _) {
                                final delta =
                                    _pageOffset(
                                          state.currentIndex.toDouble(),
                                        ) -
                                        index;
                                return _OnboardingSlide(
                                  item: item,
                                  delta: delta,
                                  textColor: ui.textPrimary,
                                  descriptionColor: ui.textMuted,
                                );
                              },
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: state.isLastPage
                            ? PrimaryButtonWidget(
                                key: const ValueKey('get-started'),
                                text: 'Get Started',
                                // buttonHeight: 38.h,
                                gradientColors: const [
                                  AppColors.primaryDarkColor,
                                  AppColors.primaryDarkButtonColor,
                                ],
                                cornerRadius: 24.r,
                                textColor: AppColors.whiteColor,
                                fontSize: FontSizes.font16Sp,
                                fontWeight: FontWeights.weight600,
                                isEnabled: !state.isCompleting,
                                onPress:
                                    state.isCompleting
                                        ? null
                                        : () => _onSkipOrGetStarted(context),
                              )
                            : SizedBox(
                                key: const ValueKey('button-spacer'),
                                height: 38.h,
                              ),
                      ),
                      12.verticalSpace,
                    ],
                  ),
                ),
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
    required this.delta,
    required this.textColor,
    required this.descriptionColor,
  });

  final OnboardingItemEntity item;

  /// Distance of this slide from the centered page (0 = centered, ±1 = one
  /// page away). Drives the swipe-linked parallax and stagger.
  final double delta;
  final Color textColor;
  final Color descriptionColor;

  @override
  Widget build(BuildContext context) {
    final t = delta.abs().clamp(0.0, 1.0);
    final contentOpacity = (1 - t).clamp(0.0, 1.0);

    // Image drifts at a slower rate than the swipe (parallax) and eases back.
    final imageDx = -delta * 60;
    final imageScale = 1 - 0.12 * t;

    return Column(
      children: [
        Flexible(
          child: Opacity(
            opacity: (1 - t * 0.4).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(imageDx, 0),
              child: Transform.scale(
                scale: imageScale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: AppPngImageView(
                      appImagePath: item.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      imageAlignment: Alignment.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        28.verticalSpace,
        // Title rises into place as the slide settles.
        Opacity(
          opacity: contentOpacity,
          child: Transform.translate(
            offset: Offset(0, t * 36),
            child: AppText(
              item.title,
              textAlign: TextAlign.center,
              color: textColor,
              fontSize: FontSizes.font30Sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        14.verticalSpace,
        // Description follows the title with a larger offset → staggered feel.
        Opacity(
          opacity: contentOpacity,
          child: Transform.translate(
            offset: Offset(0, t * 56),
            child: AppText(
              item.description,
              textAlign: TextAlign.center,
              color: descriptionColor,
              fontSize: FontSizes.font16Sp,
              fontWeight: FontWeights.weight400,
            ),
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
    final ui = AppUiColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? ui.brandPrimary
                : ui.textSecondary.withValues(alpha: 0.45),
          ),
        );
      }),
    );
  }
}
