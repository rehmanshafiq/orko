import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class SummaryBottomCard extends StatelessWidget {
  const SummaryBottomCard({
    super.key,
    required this.ui,
    required this.durationHours,
    required this.estimatedCost,
    required this.estimatedKwh,
    required this.buttonWidth,
    required this.isContinueEnabled,
    required this.onContinueToPayment,
  });

  final AppUiColors ui;
  final int durationHours;
  final int estimatedCost;
  final int estimatedKwh;
  final double buttonWidth;
  final bool isContinueEnabled;
  final VoidCallback onContinueToPayment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.cardBookingBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Estimated Cost',
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          6.verticalSpace,
          AppText(
            'Rs $estimatedCost for $durationHours hour${durationHours == 1 ? '' : 's'} ($estimatedKwh kWh estimated)',
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          16.verticalSpace,
          PrimaryButtonWidget(
            text: 'Continue to Payment',
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
          ),
        ],
      ),
    );
  }
}
