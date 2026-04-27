import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart'
    show UserBloc, OnLoadCustomerFromCache, UserInitial, UserLoading;

import '../../../../core/utils/app_routing/app_navigations.dart';
import '../../../../core/utils/app_storage/app_storage.dart';
import '../../../../core/utils/widgets/image_view/app_image_view.dart';



class SplashMobileView extends StatefulWidget {
  const SplashMobileView({super.key});

  @override
  State<SplashMobileView> createState() => _SplashMobileViewState();
}

class _SplashMobileViewState extends State<SplashMobileView> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startSplashFlow();
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
    if (AppStorage.isOnboardingCompleted) {
      AppNavigations.navigateToBottomNavigation(context);
      return;
    }

    AppNavigations.navigateToOnBoarding(context);
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width * 0.45;

    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: Center(
        child: AppPngImageView(
          appImagePath: AppImages.hubcoLogo,
          width: logoWidth,
        ),
      ),
    );
  }
}
