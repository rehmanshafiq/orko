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
    this.currency = 'PKR',
    this.pricePerKwh = 0,
    this.hasPrice = false,
  });

  final AppUiColors ui;
  final int durationHours;
  final double estimatedCost;
  final int estimatedKwh;
  final double buttonWidth;
  final bool isContinueEnabled;
  final VoidCallback onContinueToPayment;

  /// Tariff currency of the selected connector, e.g. `PKR`.
  final String currency;

  /// Selected connector's per-kWh rate.
  final double pricePerKwh;

  /// Whether a priced connector is selected; when false a hint is shown.
  final bool hasPrice;

  String _money(double value) {
    final fixed = value.toStringAsFixed(2);
    // Drop trailing ".00" for whole numbers.
    return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
  }

  @override
  Widget build(BuildContext context) {
    final hours = '$durationHours hour${durationHours == 1 ? '' : 's'}';
    final detail = hasPrice
        ? '$currency ${_money(estimatedCost)} for $hours '
            '($estimatedKwh kWh @ $currency ${_money(pricePerKwh)}/kWh)'
        : 'Select an available connector to see pricing.';

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
            detail,
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
