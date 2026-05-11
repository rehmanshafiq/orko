import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class BookingDetailRow extends StatelessWidget {
  const BookingDetailRow({
    super.key,
    required this.ui,
    required this.label,
    required this.value,
    this.emphasizeValue = false,
  });

  final AppUiColors ui;
  final String label;
  final String value;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: AppText(
            label,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ),
        12.horizontalSpace,
        Expanded(
          flex: 3,
          child: AppText(
            value,
            color: emphasizeValue
                ? AppColors.primaryDarkColor
                : ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: emphasizeValue
                ? FontWeights.weight700
                : FontWeights.weight600,
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
