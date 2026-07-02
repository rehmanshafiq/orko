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
    required this.stateLabel,
    required this.selected,
    this.enabled = true,
  });

  final AppUiColors ui;
  final String portLabel;
  final String specs;

  /// Connector state text, e.g. `Available`, `Preparing`, `Faulted`.
  final String stateLabel;
  final bool selected;

  /// When false the card is dimmed (connector not bookable).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = ui.cardBookingBackground;
    final borderColor = selected ? ui.brandPrimary : ui.borderSubtle;
    final stateColor = enabled ? ui.brandPrimary : AppColors.slotBusyYellowColor;

    final card = Container(
      width: 148.w,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                portLabel,
                color: selected
                    ? (ui.isLight ? AppColors.blackColor : AppColors.whiteColor)
                    : ui.textPrimary,
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
                  color: AppColors.iconsGreyColor,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          AppText(
            specs,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          8.verticalSpace,
          Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              stateLabel,
              color: stateColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
        ],
      ),
    );

    return enabled ? card : Opacity(opacity: 0.55, child: card);
  }
}
