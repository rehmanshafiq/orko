import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

class ChargingStationPortIconWidget extends StatelessWidget {
  const ChargingStationPortIconWidget({
    super.key,
    required this.diameter,
  });

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      height: 32.h,
      width: 32.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ui.innerIconBg,
      ),
      child: Icon(
        Icons.ev_station_rounded,
        color: ui.textPrimary.withValues(alpha: 0.88),
        size: 18.r,
      ),
    );
  }
}
