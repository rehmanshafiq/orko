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
        color: ui.searchBackground.withValues(alpha: ui.isLight ? 1 : null),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(child: _infoText()),
          8.horizontalSpace,
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ui.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _infoText() {
    const separator = ' - ';
    final separatorIndex = infoText.indexOf(separator);

    if (separatorIndex == -1) {
      return AppText(
        infoText,
        color: AppColors.whiteColor,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight400,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final prefix = infoText.substring(0, separatorIndex + separator.length);
    final stationName = infoText.substring(separatorIndex + separator.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight400,
          fontFamily: AppFonts.lexend,
        ),
        children: [
          TextSpan(
            text: prefix,
            style: TextStyle(color: ui.textSecondary),
          ),
          TextSpan(
            text: stationName,
            style: TextStyle(color: ui.textSecondaryWhite),
          ),
        ],
      ),
    );
  }
}
