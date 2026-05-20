import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart'
    show
        UserBloc,
        OnLoadCustomerFromCache,
        UserInitial,
        UserLoading,
        UserLoaded;

import '../../../../core/utils/app_routing/app_navigations.dart';
import '../../../../core/utils/app_storage/app_storage.dart';
import '../../../../core/utils/widgets/app_text.dart';

class SplashMobileView extends StatefulWidget {
  const SplashMobileView({super.key});

  @override
  State<SplashMobileView> createState() => _SplashMobileViewState();
}

class _SplashMobileViewState extends State<SplashMobileView>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(seconds: 4);

  bool _hasNavigated = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _progressAnimation;
  late final Future<void> _splashTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.25, curve: Curves.easeOut),
    );
    _progressAnimation = Tween<double>(begin: 0.08, end: 0.38).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _splashTimer = _animationController.forward();
    _startSplashFlow();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startSplashFlow() async {
    await _splashTimer;

    if (!mounted) return;

    final userBloc = context.read<UserBloc>();
    final cacheLoaded = userBloc.stream.firstWhere(
      (state) => state is! UserInitial && state is! UserLoading,
    );
    userBloc.add(const OnLoadCustomerFromCache());
    await cacheLoaded;

    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    if (!AppStorage.isOnboardingCompleted) {
      AppNavigations.navigateToOnBoarding(context);
      return;
    }

    if (userBloc.state is UserLoaded) {
      AppNavigations.navigateToBottomNavigation(context);
      return;
    }

    AppNavigations.navigateToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.splashMintBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCenterGlow(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoBadge(),
                28.verticalSpace,
                _buildBrandTitle(),
                18.verticalSpace,
                _buildSubtitleWithDividers(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 52.h,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildLoadingSection(screenWidth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterGlow() {
    return Center(
      child: Container(
        width: 340.w,
        height: 300.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(160.r),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              AppColors.whiteColor.withValues(alpha: 0.92),
              AppColors.splashMintGlow.withValues(alpha: 0.55),
              AppColors.splashMintBackground.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoBadge() {
    return Container(
      width: 92.w,
      height: 92.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF16B07E),
            AppColors.splashBrandGreen,
            Color(0xFF0A7354),
          ],
        ),
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.45),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.splashBrandGreen.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.ev_station_rounded,
        color: AppColors.whiteColor,
        size: 42.sp,
      ),
    );
  }

  Widget _buildBrandTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          'HUBCO',
          fontSize: FontSizes.font36Sp,
          fontWeight: FontWeights.weight700,
          color: AppColors.splashTextDark,
          letterSpacing: 0.8,
          height: 1.05,
        ),
        AppText(
          'CHARGE',
          fontSize: FontSizes.font36Sp,
          fontWeight: FontWeights.weight700,
          color: AppColors.splashBrandGreen,
          letterSpacing: 0.8,
          height: 1.05,
        ),
      ],
    );
  }

  Widget _buildSubtitleWithDividers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubtitleDivider(fadeFromCenter: false),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: AppText(
            'POWER YOUR JOURNEY',
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight500,
            color: AppColors.splashMutedText,
            letterSpacing: 3.6,
          ),
        ),
        _buildSubtitleDivider(fadeFromCenter: true),
      ],
    );
  }

  Widget _buildSubtitleDivider({required bool fadeFromCenter}) {
    return Container(
      width: 52.w,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fadeFromCenter ? Alignment.centerLeft : Alignment.centerRight,
          end: fadeFromCenter ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            AppColors.splashMutedText.withValues(alpha: 0.38),
            AppColors.splashMutedText.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection(double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, _) {
            return Container(
              width: screenWidth * 0.45,
              height: 3.5.h,
              decoration: BoxDecoration(
                color: AppColors.shimmerGreyColor,
                borderRadius: BorderRadius.circular(999),
              ),
              clipBehavior: Clip.antiAlias,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _progressAnimation.value.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.splashBrandGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        14.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5.w,
              height: 5.w,
              decoration: const BoxDecoration(
                color: AppColors.splashBrandGreen,
                shape: BoxShape.circle,
              ),
            ),
            7.horizontalSpace,
            AppText(
              'Initializing core systems...',
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
              color: AppColors.splashMutedText,
            ),
          ],
        ),
      ],
    );
  }
}
