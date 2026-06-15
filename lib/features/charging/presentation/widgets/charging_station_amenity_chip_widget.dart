import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/models/amenity_model.dart';

class ChargingStationAmenityChipWidget extends StatelessWidget {
  const ChargingStationAmenityChipWidget({
    super.key,
    required this.amenity,
  });

  final AmenityModel amenity;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ui.searchBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLeading(ui),
          6.horizontalSpace,
          AppText(
            amenity.label,
            color: ui.textPrimary,
            fontSize: FontSizes.font9Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }

  Widget _buildLeading(AppUiColors ui) {
    final iconColor = ui.textPrimary.withValues(alpha: 0.85);
    const fallbackIcon = Icons.local_offer_rounded;

    if (!amenity.hasImage) {
      return Icon(amenity.icon ?? fallbackIcon, size: 16.r, color: iconColor);
    }

    return CachedNetworkImage(
      imageUrl: amenity.imageUrl!,
      width: 16.r,
      height: 16.r,
      fit: BoxFit.contain,
      placeholder: (_, __) => SizedBox(width: 16.r, height: 16.r),
      errorWidget: (_, __, ___) =>
          Icon(amenity.icon ?? fallbackIcon, size: 16.r, color: iconColor),
    );
  }
}
