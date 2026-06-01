import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

class ChargingStationGlassButtonWidget extends StatelessWidget {
  const ChargingStationGlassButtonWidget({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          height: 44.r,
          width: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ui.iconGlassBackground.withValues(alpha: ui.isLight ? 0.88 : 0.55),
          ),
          child: Icon(
            icon,
            color: iconColor ?? ui.textPrimary,
            size: 22.r,
          ),
        ),
      ),
    );
  }
}
