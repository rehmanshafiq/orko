import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class StationInfoCard extends StatelessWidget {
  const StationInfoCard({
    super.key,
    required this.title,
    required this.address,
    required this.ui,
  });

  final String title;
  final String address;
  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 2,
          ),
          6.verticalSpace,
          AppText(
            address,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          10.verticalSpace,
          Row(
            children: [
              _PlugChipRow(ui: ui, label: 'CCS'),
              12.horizontalSpace,
              _PlugChipRow(ui: ui, label: 'CHAdeMO'),
              12.horizontalSpace,
              _PlugChipRow(ui: ui, label: 'Type 2'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlugChipRow extends StatelessWidget {
  const _PlugChipRow({required this.ui, required this.label});

  final AppUiColors ui;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.ev_station_outlined, size: 16.sp, color: ui.textSecondary),
        4.horizontalSpace,
        AppText(
          label,
          color: ui.textSecondary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
      ],
    );
  }
}
