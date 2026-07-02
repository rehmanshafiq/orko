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
    this.power = '',
    this.rating,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String distance;
  final String available;
  final List<String> tags;

  /// Power rating label, e.g. `'60 kWh'`. Hidden when empty.
  final String power;

  /// Average rating (e.g. popular stations). Hidden when null.
  final double? rating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    // Cap visible tags so a station with many connector types doesn't overflow.
    final visibleTags = tags.take(3).toList(growable: false);

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          5.horizontalSpace,
                          Flexible(
                            child: AppText(
                              subtitle,
                              color: ui.textMuted,
                              fontSize: FontSizes.font12Sp,
                              fontWeight: FontWeights.weight400,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  8.horizontalSpace,
                  DistanceChipWidget(text: distance),
                ],
              ),
              4.verticalSpace,
              Row(
                children: [
                  AppText(
                    available,
                    color: ui.brandSecondary,
                    fontSize: FontSizes.font12Sp,
                    fontWeight: FontWeights.weight500,
                  ),
                  if (rating != null) ...[
                    8.horizontalSpace,
                    Icon(Icons.star_rounded,
                        color: AppColors.maroonColor, size: 13.sp),
                    2.horizontalSpace,
                    AppText(
                      rating!.toStringAsFixed(1),
                      color: ui.textMuted,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight500,
                    ),
                  ],
                ],
              ),
              if (visibleTags.isNotEmpty || power.isNotEmpty) ...[
                6.verticalSpace,
                Row(
                  children: [
                    Icon(Icons.ev_station_outlined,
                        color: ui.textMuted, size: 13.sp),
                    6.horizontalSpace,
                    Icon(Icons.bolt_outlined, color: ui.textMuted, size: 13.sp),
                    // 8.horizontalSpace,
                    const Spacer(),
                    if (power.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: ui.textMuted, size: 13.sp),
                          2.horizontalSpace,
                          AppText(
                            power,
                            color: ui.textPrimary,
                            fontSize: FontSizes.font8Sp,
                            fontWeight: FontWeights.weight500,
                          ),
                          8.horizontalSpace
                        ],
                      ),
                    ],
                    // Expanded(
                    //   child: Wrap(
                    //     spacing: 4.w,
                    //     runSpacing: 4.h,
                    //     children: [
                    //       for (final tag in visibleTags)
                    //         TagChipWidget(label: tag),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
