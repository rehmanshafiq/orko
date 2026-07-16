import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';

/// Banner only — [SliverAppBar] + [FlexibleSpaceBar] drive collapse / parallax.
class ChargingStationBannerWidget extends StatelessWidget {
  const ChargingStationBannerWidget({super.key, this.bannerImage});

  /// Station banner URL from the detail API (`banner_image` key). When null or
  /// empty the bundled asset is shown instead.
  final String? bannerImage;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final url = bannerImage?.trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isEmpty)
          const _AssetBanner()
        else
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            placeholder: (_, __) => const _AssetBanner(),
            errorWidget: (_, __, ___) => const _AssetBanner(),
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

class _AssetBanner extends StatelessWidget {
  const _AssetBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.chargingStationBanner),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
