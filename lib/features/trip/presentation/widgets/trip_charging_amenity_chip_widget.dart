import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripChargingAmenityChipWidget extends StatelessWidget {
  const TripChargingAmenityChipWidget({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.homeStationCardPadding,
      decoration: BoxDecoration(
        color: ui.vehicleStatBoxBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: ui.textPrimary),
          6.horizontalSpace,
          AppText(
            label,
            color: ui.textPrimary,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight600,
          ),
        ],
      ),
    );
  }
}

