import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Empty-state card shown when a tab has no items.
class BookingEmptyState extends StatelessWidget {
  const BookingEmptyState({
    super.key,
    required this.ui,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
    this.iconBackgroundColor,
    this.iconOutlined = false,
    this.iconBorderColor,
  });

  final AppUiColors ui;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;
  final Color? iconBackgroundColor;
  final bool iconOutlined;
  final Color? iconBorderColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.mapPinBlueColor;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72.r,
            width: 72.r,
            decoration: BoxDecoration(
              color: iconOutlined
                  ? Colors.transparent
                  : (iconBackgroundColor ??
                      accent.withValues(alpha: ui.isLight ? 0.12 : 0.2)),
              shape: BoxShape.circle,
              border: iconOutlined
                  ? Border.all(
                      color: iconBorderColor ?? ui.iconContainerOutline,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Icon(icon, color: accent, size: 32.sp),
          ),
          20.verticalSpace,
          AppText(
            title,
            textAlign: TextAlign.center,
            color: ui.textPrimary,
            fontSize: FontSizes.font18Sp,
            fontWeight: FontWeights.weight700,
          ),
          8.verticalSpace,
          AppText(
            subtitle,
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight400,
          ),
        ],
      ),
    );
  }
}
