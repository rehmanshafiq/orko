import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import '../../cache/local_cache.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextDecoration? textDecoration;
  final Color? textDecorationColor;
  final double? letterSpacing;
  final double? height;
  final String? fontFamily;

  const AppText(
    this.text, {
    super.key,
    this.softWrap,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textDecoration,
    this.textDecorationColor,
    this.letterSpacing,
    this.height,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final localizedContent = LocalCache.currentLocalizeContent;
    final hasLocalizedText =
        localizedContent != null && localizedContent.containsKey(text);

    return Text(
      hasLocalizedText ? tr(text) : text,
      overflow: overflow,
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: softWrap,

      style: TextStyle(
        color: color ?? AppColors.blackColor,
        decoration: textDecoration,
        letterSpacing: letterSpacing,
        height: height,
        decorationColor: textDecorationColor,
        fontSize: fontSize ?? FontSizes.font14Sp,
        fontWeight: fontWeight ?? FontWeights.weight500,
        fontFamily: fontFamily ?? AppFonts.lexend,
        fontFamilyFallback: [fontFamily ?? AppFonts.lexend],
      ),
    );
  }
}
