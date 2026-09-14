import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';

/// Banner only — [SliverAppBar] + [FlexibleSpaceBar] drive collapse / parallax.
class ChargingStationBannerWidget extends StatelessWidget {
  const ChargingStationBannerWidget({
    super.key,
    this.bannerImage,
    this.isLoading = false,
  });

  /// Station banner URL from the detail API (`banner_image` key). When null or
  /// empty the bundled asset is shown instead — unless [isLoading] is true, in
  /// which case the shimmer is shown while the URL is still being fetched.
  final String? bannerImage;

  /// Whether the detail request that provides [bannerImage] is still in flight.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final url = bannerImage?.trim() ?? '';
    // No URL yet: shimmer while the detail request is loading, otherwise fall
    // back to the bundled asset (station genuinely has no banner).
    if (url.isEmpty) {
      return isLoading ? const _ShimmerBanner() : const _AssetBanner();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          placeholder: (_, __) => const _ShimmerBanner(),
          errorWidget: (_, __, ___) => const _AssetBanner(),
        ),
      ],
    );
  }
}

/// Animated shimmer shown while the network banner is loading. Uses the shared
/// shimmer palette and a looping gradient sweep — no external package needed.
class _ShimmerBanner extends StatefulWidget {
  const _ShimmerBanner();

  @override
  State<_ShimmerBanner> createState() => _ShimmerBannerState();
}

class _ShimmerBannerState extends State<_ShimmerBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Sweep the highlight from off-screen left to off-screen right.
        final double t = _controller.value;
        final double dx = -1.0 + 3.0 * t;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(dx - 1.0, 0),
              end: Alignment(dx + 1.0, 0),
              colors: const [
                AppColors.shimmerGreyColor,
                AppColors.shimmerHighlightColor,
                AppColors.shimmerGreyColor,
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
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
