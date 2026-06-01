import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class ChargingStationSectionTitleWidget extends StatelessWidget {
  const ChargingStationSectionTitleWidget({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return AppText(
      title,
      color: ui.textPrimary,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}
