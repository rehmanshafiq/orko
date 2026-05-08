import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripChargingStopMetricWidget extends StatelessWidget {
  const TripChargingStopMetricWidget({
    required this.label,
    required this.value,
    required this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textMuted,
          fontSize: FontSizes.font8Sp,
          fontWeight: FontWeights.weight400,
        ),
        4.verticalSpace,
        AppText(
          value,
          color: valueColor,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

