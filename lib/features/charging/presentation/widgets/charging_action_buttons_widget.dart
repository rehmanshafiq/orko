import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
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
  static const _emergencyIconColor = Color(0xFFE04545);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrimaryButtonWidget(
          text: 'Stop Charging',
          fontSize: FontSizes.font15Sp,
          onPress: onStopCharging,
          buttonColor: AppColors.transparentColor,
          strokeColor: AppColors.removeColor.withValues(alpha: 0.75),
          textColor: AppColors.removeColor,
          fontWeight: FontWeights.weight600,
          cornerRadius: 34.r,
        ),
        10.verticalSpace,
        _EmergencyStopButton(onTap: onEmergencyStop),
      ],
    );
  }
}

class _EmergencyStopButton extends StatelessWidget {
  const _EmergencyStopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(34.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.redButtonColor,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 23.r,
                height: 23.r,
                decoration: BoxDecoration(
                  color: ChargingActionButtonsWidget._emergencyGradientEnd,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              8.verticalSpace,
              AppText(
                'Emergency Stop',
                color: AppColors.whiteColor,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
