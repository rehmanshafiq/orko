import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/models/review_model.dart';

class ChargingStationReviewCardWidget extends StatelessWidget {
  const ChargingStationReviewCardWidget({
    super.key,
    required this.review,
  });

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final r = review;
    return Container(
      width: 260.w,
      height: 248.h,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                Icon(
                  i < r.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16.r,
                  color: AppColors.ratingStarColor,
                ),
                if (i < 4) 2.horizontalSpace,
              ],
            ],
          ),
          10.verticalSpace,
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: ui.innerCardBg,
                child: Center(
                  child: AppText(
                    r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: AppText(
                  r.name,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight600,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          AppText(
            r.text,
            color: ui.textPrimary.withValues(alpha: 0.88),
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
