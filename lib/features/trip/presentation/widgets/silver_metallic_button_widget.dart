import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';

/// Glossy silver pill button matching the metallic "Next" reference style.
class SilverMetallicButtonWidget extends StatelessWidget {
  const SilverMetallicButtonWidget({
    super.key,
    required this.text,
    required this.onPress,
    this.buttonHeight,
    this.cornerRadius,
  });

  final String text;
  final VoidCallback? onPress;
  final double? buttonHeight;
  final double? cornerRadius;

  static const Color _shineWhite = Color(0xFFFFFFFF);
  static const Color _silverLeft = Color(0xFFC8C8C8);
  static const Color _silverRight = Color(0xFFB2B4B3);
  static const Color _edgeShade = Color(0xFF8E8E8E);
  static const Color _borderColor = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    final radius = cornerRadius ?? 24.r;
    final borderRadius = BorderRadius.circular(radius);

    return SizedBox(
      height: buttonHeight ?? 44.h,
      width: ScreenUtil().screenWidth,
      child: Material(
        color: AppColors.transparentColor,
        child: InkWell(
          onTap: onPress,
          borderRadius: borderRadius,
          splashColor: _edgeShade.withValues(alpha: 0.25),
          highlightColor: _shineWhite.withValues(alpha: 0.12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: _borderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withValues(alpha: 0.45),
                  blurRadius: 2,
                  offset: Offset(0, 1.5.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _silverLeft,
                          _shineWhite,
                          _silverRight,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2.h,
                    left: 8.w,
                    child: Container(
                      width: 28.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(radius),
                          bottomRight: Radius.circular(10.r),
                        ),
                        gradient: RadialGradient(
                          center: const Alignment(-0.6, -0.8),
                          radius: 1.1,
                          colors: [
                            _shineWhite,
                            _shineWhite.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
