import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';

class PortCard extends StatelessWidget {
  const PortCard({
    super.key,
    required this.ui,
    required this.portLabel,
    required this.specs,
    required this.selected,
    required this.onTap,
  });

  final AppUiColors ui;
  final String portLabel;
  final String specs;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        selected ? AppColors.primaryDarkColor.withValues(alpha: 0.95) : ui.cardBackground;
    final borderColor = selected ? AppColors.primaryDarkColor : ui.borderSubtle;
    final glow = selected
        ? [
            BoxShadow(
              color: AppColors.primaryDarkColor.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ]
        : <BoxShadow>[];

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          width: 148.w,
          padding: AppUtils.all12Padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: glow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    portLabel,
                    color: selected ? AppColors.whiteColor : ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: AppSvgImageView(
                      appImagePath: AppImages.icCss2Png,
                      width: 42.sp,
                      height: 42.sp,
                      fit: BoxFit.contain,
                      color: selected ? AppColors.whiteColor : AppColors.iconsGreyColor,
                    ),
                  ),
                ],
              ),
              8.verticalSpace,
              AppText(
                specs,
                color: selected ? AppColors.whiteColor : ui.textSecondary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: AppUtils.horizontal8Vertical4Padding,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.whiteColor.withValues(alpha: 0.25)
                        : AppColors.primaryDarkColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: AppText(
                    'Available',
                    color: AppColors.whiteColor.withValues(alpha: selected ? 1.0 : 0.9),
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
