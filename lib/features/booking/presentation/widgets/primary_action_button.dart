import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    this.text = 'Start Charge',
  });

  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return PrimaryButtonWidget(
      text: text,
      onPress: onPressed,
      buttonWidth: double.infinity,
      buttonHeight: 52.h,
      cornerRadius: 12.r,
      buttonColor: AppColors.primaryDarkColor,
      textColor: AppColors.whiteColor,
      fontSize: FontSizes.font15Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}
