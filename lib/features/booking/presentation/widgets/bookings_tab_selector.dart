import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

/// Pill-style segmented control for the My Bookings tabs.
class BookingsTabSelector extends StatelessWidget {
  const BookingsTabSelector({
    super.key,
    required this.ui,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final AppUiColors ui;
  final BookingTab selectedTab;
  final ValueChanged<BookingTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: ui.isLight
            ? AppColors.shimmerGreyColor
            : AppColors.whiteColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: BookingTab.values.map((tab) {
          return Expanded(
            child: _TabSegment(
              ui: ui,
              label: tab.label,
              isSelected: tab == selectedTab,
              onTap: () => onTabSelected(tab),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.ui,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final AppUiColors ui;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? ui.cardBackground : AppColors.transparentColor,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.blackColor.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AppText(
          label,
          textAlign: TextAlign.center,
          color: isSelected ? ui.textPrimary : ui.textSecondary,
          fontSize: FontSizes.font14Sp,
          fontWeight:
              isSelected ? FontWeights.weight700 : FontWeights.weight500,
        ),
      ),
    );
  }
}
