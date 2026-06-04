import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';

class StationInfoCard extends StatelessWidget {
  const StationInfoCard({
    super.key,
    required this.title,
    required this.address,
    required this.ui,
  });

  final String title;
  final String address;
  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 2,
          ),
          6.verticalSpace,
          AppText(
            address,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          10.verticalSpace,
          Row(
            children: [
              _PlugChipRow(
                ui: ui,
                label: 'CCS',
                assetPath: AppImages.icCss2,
              ),
              12.horizontalSpace,
              _PlugChipRow(
                ui: ui,
                label: 'CHAdeMO',
                assetPath: AppImages.icCss2,
              ),
              12.horizontalSpace,
              _PlugChipRow(
                ui: ui,
                label: 'Type 2',
                assetPath: AppImages.icCss2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlugChipRow extends StatelessWidget {
  const _PlugChipRow({
    required this.ui,
    required this.label,
    required this.assetPath,
  });

  final AppUiColors ui;
  final String label;
  final String assetPath;

  static const _iconSize = 28.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlugChipIcon(
          assetPath: assetPath,
          color: ui.textSecondary,
        ),
        4.horizontalSpace,
        AppText(
          label,
          color: ui.textSecondary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
      ],
    );
  }
}

class _PlugChipIcon extends StatelessWidget {
  const _PlugChipIcon({
    required this.assetPath,
    required this.color,
  });

  final String assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = _PlugChipRow._iconSize.sp;

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
