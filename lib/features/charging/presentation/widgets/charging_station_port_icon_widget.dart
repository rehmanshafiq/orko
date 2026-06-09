import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';

class ChargingStationPortIconWidget extends StatelessWidget {
  const ChargingStationPortIconWidget({
    super.key,
    required this.diameter,
  });

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      height: 32.h,
      width: 32.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ui.innerIconBg,
      ),
      alignment: Alignment.center,
      child: AppSvgImageView(
        appImagePath: AppImages.icPortCharger,
        color: ui.textPrimary.withValues(alpha: 0.88),
        width: 19.r,
        height: 19.r,
      ),
    );
  }
}
