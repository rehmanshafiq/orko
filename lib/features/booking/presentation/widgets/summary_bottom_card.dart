import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class SummaryBottomCard extends StatelessWidget {
  const SummaryBottomCard({
    super.key,
    required this.buttonWidth,
    required this.isContinueEnabled,
    required this.onContinueToPayment,
  });

  final double buttonWidth;
  final bool isContinueEnabled;
  final VoidCallback onContinueToPayment;

  @override
  Widget build(BuildContext context) {
    return PrimaryButtonWidget(
      text: 'Continue to Booking',
      onPress: onContinueToPayment,
      gradientColors: const [
        AppColors.primaryDarkColor,
        AppColors.primaryDarkButtonColor,
      ],
      textColor: AppColors.whiteColor,
      fontWeight: FontWeights.weight700,
      fontSize: FontSizes.font15Sp,
      buttonWidth: buttonWidth,
      cornerRadius: 24.r,
      isEnabled: isContinueEnabled,
    );
  }
}
