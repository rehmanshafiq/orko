import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppSvgImageView extends StatelessWidget {
  const AppSvgImageView({
    super.key,
    required this.appImagePath,
    this.fit = BoxFit.contain,
    this.height,
    this.imageAlignment = Alignment.center,
    this.width,
    this.color,
    this.matchTextDirection = true,
  });
  final String? appImagePath;
  final BoxFit? fit;
  final Alignment? imageAlignment;
  final double? height;
  final double? width;
  final Color? color;
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      appImagePath!,
      fit: fit!,
      matchTextDirection: matchTextDirection,
      alignment: imageAlignment!,
      height: height,
      width: width,
      // ignore: deprecated_member_use
      color: color,
    );
  }
}

class AppPngImageView extends StatelessWidget {
  const AppPngImageView({
    super.key,
    required this.appImagePath,
    this.fit = BoxFit.contain,
    this.height,
    this.imageAlignment,
    this.width,
    this.color,
    this.matchDirection = false,
  });

  final String? appImagePath;
  final BoxFit? fit;
  final Alignment? imageAlignment;
  final double? height;
  final double? width;
  final Color? color;
  final bool? matchDirection;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      appImagePath!,
      fit: fit!,
      height: height,
      width: width,
      color: color,
      matchTextDirection: matchDirection ?? false,
    );
  }
}
