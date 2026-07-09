import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';

/// Connector plug icon(s) with an optional peak-power label, shown on station
/// cards across the home and filter screens.
class StationPlugIconsRowWidget extends StatelessWidget {
  const StationPlugIconsRowWidget({
    super.key,
    required this.color,
    this.powerLabel = '',
  });

  final Color color;

  /// Peak power label (e.g. `60 kW`) shown next to the plug icon; hidden empty.
  final String powerLabel;

  static const iconSize = 34.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PlugIconWidget(assetPath: AppImages.icCcs, color: color),
        // 2.horizontalSpace,
        // PlugIconWidget(assetPath: AppImages.icCcs1, color: color),
        // 2.horizontalSpace,
        PlugIconWidget(assetPath: AppImages.icCss2, color: color),
        if (powerLabel.isNotEmpty) ...[
          8.horizontalSpace,
          AppText(
            powerLabel,
            color: color,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
        50.horizontalSpace,
      ],
    );
  }
}

class PlugIconWidget extends StatelessWidget {
  const PlugIconWidget({
    super.key,
    required this.assetPath,
    required this.color,
  });

  final String assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = StationPlugIconsRowWidget.iconSize.sp;

    if (assetPath.endsWith('.svg')) {
      return AppSvgImageView(
        appImagePath: assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
      );
    }

    return AppPngImageView(
      appImagePath: assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
