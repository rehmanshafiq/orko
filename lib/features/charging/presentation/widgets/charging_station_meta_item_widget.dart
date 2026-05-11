import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class ChargingStationMetaItemWidget extends StatelessWidget {
  const ChargingStationMetaItemWidget({
    super.key,
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.textFontWeight,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final FontWeight textFontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18.r),
        4.horizontalSpace,
        AppText(
          text,
          color: textColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: textFontWeight,
        ),
      ],
    );
  }
}
