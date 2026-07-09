import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Rating overview: the average rating with stars and the total review count.
class StationReviewsSummaryWidget extends StatelessWidget {
  const StationReviewsSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalCount,
  });

  final double averageRating;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final rounded = averageRating.round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          _formatRating(averageRating),
          color: ui.textPrimary,
          fontSize: FontSizes.font26Sp,
          fontWeight: FontWeights.weight700,
        ),
        12.horizontalSpace,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    i < rounded
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14.r,
                    color: AppColors.ratingStarColor,
                  ),
              ],
            ),
            4.verticalSpace,
            AppText(
              totalCount == 1 ? '1 review' : '$totalCount reviews',
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          ],
        ),
      ],
    );
  }

  /// `4.5` → `4.5`, `4.0` → `4`.
  String _formatRating(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}
