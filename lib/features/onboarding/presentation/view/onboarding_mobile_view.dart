import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_routing/app_navigations.dart';
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
    if (_pageController.hasClients && _pageController.position.haveDimensions) {
      return _pageController.page ?? fallback;
    }
    return fallback;
  }

  Future<void> _onGetStarted(BuildContext context) async {
    await context.read<OnboardingCubit>().complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText(
                  state.errorMessage!,
                  color: AppColors.whiteColor,
                ),
              ),
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
                color: AppColors.whiteColor,
              ),
            );
          }

          return Stack(
            children: [
              // Full-bleed background image per slide (edge to edge, behind
              // the status bar) with a swipe-linked parallax drift.
              Positioned.fill(
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
                            _pageOffset(state.currentIndex.toDouble()) - index;
                        return _OnboardingSlide(item: item, delta: delta);
                      },
                    );
                  },
                ),
              ),

              // Bottom control: single "Get Started" pill. Muted until the
              // last slide is reached, then enabled.
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: SlideTransition(
                      position: _entrySlide,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                        child: _GetStartedBar(
                          // Single onboarding screen: always actionable.
                          isEnabled: !state.isCompleting,
                          isBusy: state.isCompleting,
                          onTap: () => _onGetStarted(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.item,
    required this.delta,
  });

  final OnboardingItemEntity item;

  /// Distance of this slide from the centered page (0 = centered, ±1 = one
  /// page away). Drives the swipe-linked parallax and stagger.
  final double delta;

  @override
  Widget build(BuildContext context) {
    final t = delta.abs().clamp(0.0, 1.0);
    final contentOpacity = (1 - t).clamp(0.0, 1.0);

    // Image drifts at a slower rate than the swipe (parallax).
    final imageDx = -delta * 40;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background photo.
        Transform.translate(
          offset: Offset(imageDx, 0),
          child: Transform.scale(
            scale: 1.06,
            child: AppPngImageView(
              appImagePath: item.imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              imageAlignment: Alignment.center,
            ),
          ),
        ),

        // Scrim to keep the headline legible over the photo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.transparentColor,
                AppColors.blackColor,
              ],
            ),
          ),
        ),

        // Headline + description, sitting above the bottom controls.
        Align(
          alignment: Alignment.bottomLeft,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 140.h),
              child: Opacity(
                opacity: contentOpacity,
                child: Transform.translate(
                  offset: Offset(0, t * 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: item.title,
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontFamily: AppFonts.lexend,
                            fontSize: FontSizes.font30Sp,
                            fontWeight: FontWeights.weight400,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(
                              text: item.titleHighlight,
                              style: TextStyle(
                                fontWeight: FontWeights.weight700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        12.verticalSpace,
                        AppText(
                          item.description,
                          color: AppColors.whiteColor.withValues(alpha: 0.7),
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom "Get Started" pill: a rounded, frosted bar with the label on the
/// left and a circular arrow on the right. Rendered muted (non-interactive)
/// until the final slide is reached, then enabled.
class _GetStartedBar extends StatelessWidget {
  const _GetStartedBar({
    required this.isEnabled,
    required this.isBusy,
    required this.onTap,
  });

  final bool isEnabled;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double opacity = isEnabled ? 1 : 0.45;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: opacity,
      child: Material(
        color: AppColors.transparentColor,
        borderRadius: BorderRadius.circular(40.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(40.r),
          onTap: isEnabled ? onTap : null,
          child: Container(
            height: 64.h,
            padding: EdgeInsets.fromLTRB(28.w, 8.h, 8.h, 8.h),
            decoration: BoxDecoration(
              color: AppColors.blackColor,
              borderRadius: BorderRadius.circular(40.r),
              border: Border.all(
                color: AppColors.blackColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    'Get Started',
                    color: AppColors.onboardingArrowBgColor,
                    fontSize: FontSizes.font16Sp,
                    fontWeight: FontWeights.weight500,
                  ),
                ),
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: const BoxDecoration(
                    color: AppColors.onboardingArrowBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isBusy
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.blackColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward,
                          color: AppColors.blackColor,
                          size: 22.sp,
                          weight: 700,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
