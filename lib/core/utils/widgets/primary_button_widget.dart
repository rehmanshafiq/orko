import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import 'app_text.dart';
import 'image_view/app_image_view.dart';

class PrimaryButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPress;
  final FontWeight? fontWeight;
  final double? buttonWidth;
  final double? buttonHeight;
  final double? fontSize;
  final Color? buttonColor;
  final Color? strokeColor;
  final Color? textColor;
  final String? icon;
  final IconData? leadingIcon;
  final bool isEnabled;
  final double? iconHeight;
  final double? iconWidth;
  final double? cornerRadius;
  /// When set, overrides the default brand button gradient (top → bottom).
  final List<Color>? gradientColors;
  /// Optional second line (e.g. helper text), centered under [text].
  final String? subtitle;
  final Color? subtitleColor;
  final double? subtitleFontSize;
  final FontWeight? subtitleFontWeight;

  const PrimaryButtonWidget({
    super.key,
    required this.text,
    this.buttonWidth,
    required this.onPress,
    this.fontWeight,
    this.buttonHeight,
    this.fontSize,
    this.buttonColor,
    this.strokeColor,
    this.textColor,
    this.icon,
    this.leadingIcon,
    this.isEnabled = true,
    this.iconHeight,
    this.iconWidth,
    this.cornerRadius,
    this.gradientColors,
    this.subtitle,
    this.subtitleColor,
    this.subtitleFontSize,
    this.subtitleFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    // Filled, enabled buttons get the app-wide vertical brand gradient
    // (brand green on top, dark green at the bottom). Outlined buttons
    // (with a [strokeColor]) and disabled buttons keep their solid color.
    final bool useGradient = isEnabled && strokeColor == null;

    final OutlinedBorder buttonShape = cornerRadius != null
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius!),
          )
        : const StadiumBorder();

    final Widget button = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: !isEnabled
              ? AppColors.thumbBarGreyColor
              : useGradient
                  ? AppColors.transparentColor
                  : (buttonColor ?? AppColors.kPrimaryColor),
          elevation: useGradient ? 0 : null,
          shadowColor: useGradient ? AppColors.transparentColor : null,
          surfaceTintColor:
              useGradient ? AppColors.transparentColor : null,
          shape: buttonShape,
          side: strokeColor != null
              ? BorderSide(
              color: isEnabled
                  ? strokeColor!
                  : AppColors.thumbBarGreyColor
          )
              : BorderSide.none,
          disabledBackgroundColor: AppColors.thumbBarGreyColor,
          disabledForegroundColor: AppColors.thumbBarGreyColor,
          padding: subtitle != null
              ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h)
              : null,
        ),
        onPressed: isEnabled ? onPress : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: iconHeight ?? 18.sp,
                    color: isEnabled
                        ? (textColor ?? AppColors.whiteColor)
                        : AppColors.greyColor,
                  ),
                  8.horizontalSpace,
                ] else if (icon != null) ...[
                  AppSvgImageView(
                    height: iconHeight?.h,
                    width: iconWidth?.w,
                    appImagePath: icon,
                    color: isEnabled
                        ? (textColor ?? AppColors.whiteColor)
                        : AppColors.greyColor,
                  ),
                  9.horizontalSpace,
                ],
                Flexible(
                  child: AppText(
                    text,
                    color: isEnabled
                        ? (textColor ?? AppColors.whiteColor)
                        : AppColors.greyColor,
                    fontSize: fontSize ?? FontSizes.font12Sp,
                    fontWeight: fontWeight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              4.verticalSpace,
              AppText(
                subtitle!,
                textAlign: TextAlign.center,
                color: isEnabled
                    ? (subtitleColor ??
                        (textColor ?? AppColors.whiteColor)
                            .withValues(alpha: 0.92))
                    : AppColors.greyColor,
                fontSize: subtitleFontSize ?? FontSizes.font12Sp,
                fontWeight: subtitleFontWeight ?? FontWeights.weight400,
              ),
            ],
          ],
        ),
      );

    return SizedBox(
      height: buttonHeight ?? 44.h,
      width: buttonWidth ?? ScreenUtil().screenWidth,
      child: useGradient
          ? DecoratedBox(
              decoration: ShapeDecoration(
                shape: buttonShape,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors ?? AppColors.brandButtonGradientColors,
                ),
              ),
              child: button,
            )
          : button,
    );
  }
}