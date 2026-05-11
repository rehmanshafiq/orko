import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class StationInfoWidget extends StatelessWidget {
  const StationInfoWidget({
    super.key,
    required this.infoText,
    required this.ui,
  });

  final String infoText;
  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUtils.vertical10Horizontal8Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground.withValues(alpha: ui.isLight ? 1 : 0.65),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              infoText,
              color: ui.textSecondary,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          8.horizontalSpace,
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ui.textSecondary,
          ),
        ],
      ),
    );
  }
}
