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
  final bool isEnabled;
  final double? iconHeight;
  final double? iconWidth;
  final double? cornerRadius;

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
    this.isEnabled = true,
    this.iconHeight,
    this.iconWidth,
    this.cornerRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buttonHeight ?? 44.h,
      width: buttonWidth ?? ScreenUtil().screenWidth,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (buttonColor ?? AppColors.kPrimaryColor)
              : AppColors.thumbBarGreyColor,
          shape: cornerRadius != null
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cornerRadius!),
                )
              : null,
          side: strokeColor != null
              ? BorderSide(
              color: isEnabled
                  ? strokeColor!
                  : AppColors.thumbBarGreyColor
          )
              : BorderSide.none,
          disabledBackgroundColor: AppColors.thumbBarGreyColor,
          disabledForegroundColor: AppColors.thumbBarGreyColor,
        ),
        onPressed: isEnabled ? onPress : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
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
            AppText(
              text,
              color: isEnabled
                  ? (textColor ?? AppColors.whiteColor)
                  : AppColors.greyColor,
              fontSize: fontSize ?? FontSizes.font12Sp,
              fontWeight: fontWeight,
            ),
          ],
        ),
      ),
    );
  }
}