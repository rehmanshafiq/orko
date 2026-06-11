import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart'
    show
        UserBloc,
        OnLoadCustomerFromCache,
        UserInitial,
        UserLoading,
        UserLoaded;

import '../../../../core/utils/app_routing/app_navigations.dart';
import '../../../../core/utils/app_storage/app_storage.dart';
import '../../../../core/utils/widgets/image_view/app_image_view.dart';



class SplashMobileView extends StatefulWidget {
  const SplashMobileView({super.key});

  @override
  State<SplashMobileView> createState() => _SplashMobileViewState();
}

class _SplashMobileViewState extends State<SplashMobileView>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Single zoom-out from a larger scale down to the natural size.
    _scaleAnimation = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _startSplashFlow();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startSplashFlow() async {
    await Future.delayed(const Duration(seconds: 3));

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
    final logoWidth = MediaQuery.sizeOf(context).width * 0.45;
    final ui = AppUiColors.of(context);

    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AppPngImageView(
            appImagePath: ui.isLight
                ? AppImages.hubcoLogoLight
                : AppImages.hubcoLogo,
            width: logoWidth,
          ),
        ),
      ),
    );
  }
}
