import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart'
    show
        UserBloc,
        OnLoadCustomerFromCache,
        UserInitial,
        UserLoading,
        UserLoaded;
import 'package:orko_hubco/core/services/live_charging/live_charging_notification_controller.dart';
import 'package:orko_hubco/core/services/push_notification_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/get_user_usecase.dart';

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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final userBloc = context.read<UserBloc>();
    final cacheLoaded = userBloc.stream.firstWhere(
      (state) => state is! UserInitial && state is! UserLoading,
    );
    userBloc.add(const OnLoadCustomerFromCache());
    await cacheLoaded;

    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    // if (!AppStorage.isOnboardingCompleted) {
    //   AppNavigations.navigateToOnBoarding(context);
    //   return;
    // }

    // A real cached session, or an explicit guest choice, both land on home.
    if (userBloc.state is UserLoaded || AppStorage.isGuest) {
      // For a real logged-in session, refresh the cached user from the server
      // in the background (best-effort — failures keep the cached copy).
      if (userBloc.state is UserLoaded && !AppStorage.isGuest) {
        unawaited(_refreshUserFromServer(userBloc));
      }
      // If the app was launched (from a killed state) by tapping a
      // notification, deep-link straight to its target with a single
      // declarative navigation, so nothing clobbers it. Only fall back to the
      // default home shell when there was no launch tap to handle.
      final handledLaunch =
          await sl<PushNotificationService>().applyLaunchIntent();
      if (!mounted) return;
      if (!handledLaunch) {
        AppNavigations.navigateToBottomNavigation(context);
        // Cold start from tapping the ongoing live-charging notification:
        // route to the Live tab if that intent was recorded.
        unawaited(
          sl<LiveChargingNotificationController>().routePendingOpenLiveTabIfAny(),
        );
      }
      return;
    }

    AppNavigations.navigateToLogin(context);
  }

  /// Calls `getUser`, which refreshes the cached user, then reflects it in the
  /// [UserBloc]. Best-effort: a failure leaves the existing cached user intact.
  Future<void> _refreshUserFromServer(UserBloc userBloc) async {
    final result = await sl<GetUserUseCase>()(const NoParams());
    result.fold(
      (_) {},
      (_) {
        if (!userBloc.isClosed) {
          userBloc.add(const OnLoadCustomerFromCache());
        }
      },
    );
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
