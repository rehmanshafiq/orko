import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripSectionTitleWidget extends StatelessWidget {
  const TripSectionTitleWidget({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      color: AppUiColors.of(context).textPrimary,
      fontSize: FontSizes.font16Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}

