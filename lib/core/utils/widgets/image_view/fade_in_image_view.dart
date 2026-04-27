import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart' as svg;

import 'app_image_view.dart';

class AppFadeInImageView extends StatelessWidget {
  const AppFadeInImageView({
    super.key,
    required this.imageUrl,
    required this.errorImage,
    required this.height,
    required this.width,
    this.isNetwork = false,
  });
  final String? imageUrl;
  final String? errorImage;
  final double? height;
  final double? width;
  final bool? isNetwork;

  @override
  Widget build(BuildContext context) {
    return FadeInImage(
      image: AssetImage(imageUrl!),
      placeholder: svg.Svg(errorImage!),
      imageErrorBuilder: (context, error, stackTrace) {
        return ClipRRect(
          child: AppSvgImageView(appImagePath: errorImage, fit: BoxFit.cover),
        );
      },
      placeholderFit: BoxFit.cover,
      height: height,
      width: width,
      fit: BoxFit.cover,
      fadeInCurve: Curves.fastOutSlowIn,
      
      fadeOutCurve: Curves.fastLinearToSlowEaseIn,
    );
  }
}

class AppNetworkFadeInImageView extends StatelessWidget {
  const AppNetworkFadeInImageView({
    super.key,
    required this.imageUrl,
    required this.errorImage,
    required this.height,
    required this.width,
    this.radius = 0,
    this.showShadow = false,
  });
  final String? imageUrl;
  final String? errorImage;
  final double? height;
  final double? width;
  final bool? showShadow;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      height: height,
      width: width,
      
      fit: BoxFit.cover,
      imageBuilder: (ctx, imageProvider) =>
          CircleAvatar(radius: radius != 0 ? radius : 40, backgroundImage: imageProvider),
      errorWidget: (ctx, _, __) => AppSvgImageView(appImagePath: errorImage),
      fadeInCurve: Curves.fastOutSlowIn,
      placeholder: (ctx, val) => AppSvgImageView(appImagePath: errorImage),
      cacheKey: imageUrl!,
      filterQuality: FilterQuality.low,
      fadeOutCurve: Curves.fastLinearToSlowEaseIn,
    );
  }
}

class NetworkImageWithBlurPlaceholder extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double? height;
  final Widget? errorWidget;
  final BoxFit boxFit;

  const NetworkImageWithBlurPlaceholder({
    super.key,
    required this.imageUrl,
    required this.width,
    this.height,
    this.errorWidget,
    this.boxFit = BoxFit.cover,
  });

  @override
  State<NetworkImageWithBlurPlaceholder> createState() => _NetworkImageWithBlurPlaceholderState();
}

class _NetworkImageWithBlurPlaceholderState extends State<NetworkImageWithBlurPlaceholder>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Get device pixel ratio for high DPI displays (e.g., iPhone 15 Pro Max has 3.0)
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenSize = MediaQuery.of(context).size;

    // Calculate cache size based on device pixel ratio
    // For large banner images, we need high resolution cache
    // Use screen dimensions when widget size is infinite (flexible layouts)
    double maxDimension;
    if (widget.width == double.infinity ||
        (widget.height != null && widget.height == double.infinity)) {
      // For flexible layouts, estimate based on screen size
      // Large banners can be up to ~600h in logical pixels, at 3x = 1800px
      // Cache at 3x that for extra quality: 5400px
      maxDimension = (screenSize.height * 0.5).clamp(400, 800);
    } else {
      // Use actual widget dimensions when available
      maxDimension =
          widget.width > (widget.height ?? 0) ? widget.width : (widget.height ?? widget.width);
    }

    // Calculate cache: devicePixelRatio * maxDimension * 3 (for extra quality buffer)
    // For iPhone 15 Pro Max (3x): 800 * 3 * 3 = 7200px cache
    // Clamp between 3000 and 8000 to handle all cases including large banners
    final baseCacheSize = (devicePixelRatio * maxDimension * 3).ceil();
    final cacheSize = baseCacheSize.clamp(3000, 8000);

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      maxWidthDiskCache: cacheSize,
      maxHeightDiskCache: cacheSize,
      filterQuality: FilterQuality.high,
      fadeInDuration: Durations.medium4,
      fadeOutDuration: Durations.medium4,
      fit: widget.boxFit,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        width: widget.width,
        height: widget.height,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.grey[300]?.withOpacity(0.5),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => widget.errorWidget ?? Icon(Icons.image_not_supported),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
