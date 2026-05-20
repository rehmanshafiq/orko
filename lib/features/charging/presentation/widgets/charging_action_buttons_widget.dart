import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class ChargingActionButtonsWidget extends StatelessWidget {
  const ChargingActionButtonsWidget({
    super.key,
    required this.onStopCharging,
    required this.onEmergencyStop,
  });

  final VoidCallback onStopCharging;
  final VoidCallback onEmergencyStop;

  static const _emergencyGradientStart = Color(0xFF6E1118);
  static const _emergencyGradientEnd = Color(0xFFA31C25);

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      children: [
        PrimaryButtonWidget(
          text: 'Stop Charging',
          onPress: onStopCharging,
          buttonColor: AppColors.transparentColor,
          strokeColor: AppColors.removeColor,
          textColor: AppColors.removeColor,
          fontWeight: FontWeights.weight600,
          cornerRadius: 12.r,
        ),
        10.verticalSpace,
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_emergencyGradientStart.withValues(alpha: 0.4),
                _emergencyGradientEnd.withValues(alpha: 0.4),],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: PrimaryButtonWidget(
            text: 'Emergency Stop',
            onPress: onEmergencyStop,
            buttonColor: AppColors.transparentColor,
            textColor: AppColors.whiteColor,
            fontWeight: FontWeights.weight700,
            cornerRadius: 12.r,
          ),
        ),
      ],
    );
  }
}
