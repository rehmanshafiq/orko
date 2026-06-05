import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripHeaderWidget extends StatelessWidget {
  const TripHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return AppText(
      'Trip Planner',
      color: ui.textPrimary,
      fontSize: FontSizes.font22Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}

