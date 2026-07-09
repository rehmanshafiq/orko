import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Modern rating overview card: a gradient rating badge, fractional star row,
/// and the total review count on a soft brand-tinted surface.
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
    return Row(
      children: [
        _RatingBadge(rating: averageRating),
        14.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _StarRow(rating: averageRating),
              6.verticalSpace,
              AppText(
                totalCount == 1
                    ? 'Based on 1 review'
                    : 'Based on $totalCount reviews',
                color: ui.textSecondary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The large rating number inside a filled brand-gradient chip.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          _formatRating(rating),
          color: AppColors.whiteColor,
          fontSize: FontSizes.font22Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }

  /// `4.8` → `4.8`, `4.0` → `4`.
  String _formatRating(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

/// Five stars with half-star support so `4.8` reads as (nearly) full.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          Icon(_iconFor(i), size: 18.r, color: AppColors.ratingStarColor),
          if (i < 4) 2.horizontalSpace,
        ],
      ],
    );
  }

  IconData _iconFor(int index) {
    if (rating >= index + 1) return Icons.star_rounded;
    if (rating >= index + 0.5) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }
}
