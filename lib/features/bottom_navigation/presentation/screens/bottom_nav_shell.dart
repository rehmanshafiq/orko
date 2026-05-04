import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Shell screen that wraps the bottom navigation bar.
/// Uses [StatefulShellRoute] from go_router for nested navigation,
/// preserving each tab's navigation stack independently.
class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: AppUtils.bottomNavOuterPadding,
          child: Container(
            height: 56.h,
            padding: AppUtils.bottomNavInnerPadding,
            decoration: BoxDecoration(
              color: AppColors.bottomNavBackgroundColor,
              borderRadius: BorderRadius.circular(2.r),
              border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  isActive: navigationShell.currentIndex == 0,
                  onTap: () => _onTapBranch(0),
                  activeBackground: true,
                ),
                _buildNavItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Bookings',
                  isActive: navigationShell.currentIndex == 2,
                  onTap: () => _onTapBranch(2),
                  activeBackground: true,
                ),
                _buildNavItem(
                  icon: Icons.alt_route_rounded,
                  label: 'Trip',
                  isActive: navigationShell.currentIndex == 3,
                  onTap: () => _onTapBranch(3),
                  activeBackground: true,
                ),
                _buildNavItem(
                  icon: Icons.bolt_outlined,
                  label: 'Charging',
                  isActive: navigationShell.currentIndex == 4,
                  onTap: () => _onTapBranch(4),
                  activeBackground: true,
                ),
                _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isActive: navigationShell.currentIndex == 1,
                  onTap: () => _onTapBranch(1),
                  activeBackground: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTapBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
    bool activeBackground = false,
  }) {
    final Color itemColor =
        isActive ? AppColors.primaryDarkColor : AppColors.whiteColor.withValues(alpha: 0.68);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: AppUtils.bottomNavItemVerticalPadding,
          decoration: BoxDecoration(
            color: activeBackground && isActive
                ? AppColors.primaryDarkColor.withValues(alpha: 0.15)
                : AppColors.transparentColor,
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: itemColor, size: 23),
              2.verticalSpace,
              AppText(
                label,
                color: itemColor,
                fontSize: FontSizes.font10Sp,
                fontWeight: isActive ? FontWeights.weight500 : FontWeights.weight400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
