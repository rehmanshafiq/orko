import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/search/presentation/widgets/distance_chip_widget.dart';
import 'package:orko_hubco/features/search/presentation/widgets/tag_chip_widget.dart';

class StationCardWidget extends StatelessWidget {
  const StationCardWidget({
    required this.title,
    required this.subtitle,
    required this.distance,
    required this.available,
    required this.tags,
    super.key,
  });

  final String title;
  final String subtitle;
  final String distance;
  final String available;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.homeStationCardPadding,
      decoration: BoxDecoration(
        color: ui.cardBackground.withValues(alpha: ui.isLight ? 1 : 0.9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: AppText(
                        title,
                        color: ui.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    5.horizontalSpace,
                    AppText(
                      subtitle,
                      color: ui.textMuted,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              DistanceChipWidget(text: distance),
            ],
          ),
          4.verticalSpace,
          AppText(
            available,
            color: ui.brandSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
          6.verticalSpace,
          Row(
            children: [
              Icon(Icons.ev_station_outlined, color: ui.textMuted, size: 13.sp),
              6.horizontalSpace,
              Icon(Icons.bolt_outlined, color: ui.textMuted, size: 13.sp),
              8.horizontalSpace,
              TagChipWidget(label: tags[0]),
              4.horizontalSpace,
              TagChipWidget(label: tags[1]),
            ],
          ),
        ],
      ),
    );
  }
}

