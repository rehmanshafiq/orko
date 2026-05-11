import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';

/// Banner only — [SliverAppBar] + [FlexibleSpaceBar] drive collapse / parallax.
class ChargingStationBannerWidget extends StatelessWidget {
  const ChargingStationBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.chargingStationBanner),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.blackColor.withValues(alpha: ui.isLight ? 0.15 : 0.25),
                AppColors.blackColor.withValues(alpha: ui.isLight ? 0.45 : 0.72),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
