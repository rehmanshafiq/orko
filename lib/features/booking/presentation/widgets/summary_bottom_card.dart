import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class SummaryBottomCard extends StatelessWidget {
  const SummaryBottomCard({
    super.key,
    required this.buttonWidth,
    required this.isContinueEnabled,
    required this.onContinueToPayment,
  });

  static const String _label = 'Continue to Book';

  final double buttonWidth;
  final bool isContinueEnabled;
  final VoidCallback onContinueToPayment;

  @override
  Widget build(BuildContext context) {
    // No slot selected yet: a gray outline-only button instead of the filled
    // grey disabled state.
    if (!isContinueEnabled) {
      final ui = AppUiColors.of(context);
      return Container(
        height: 44.h,
        width: buttonWidth,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: ui.borderMuted),
        ),
        child: AppText(
          _label,
          color: ui.textPrimary,
          fontSize: FontSizes.font15Sp,
          fontWeight: FontWeights.weight700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    }

    return PrimaryButtonWidget(
      text: _label,
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
    );
  }
}
