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
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: AppUtils.bottomNavOuterPadding,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ui.bottomNavContainerBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26.r),
                topRight: Radius.circular(26.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: ui.bottomNavShadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26.r),
                topRight: Radius.circular(26.r),
              ),
              child: Padding(
                padding: AppUtils.bottomNavInnerPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(
                      context: context,
                      icon: Icons.map_outlined,
                      activeIcon: Icons.map_rounded,
                      label: 'Map',
                      isActive: navigationShell.currentIndex == 0,
                      onTap: () => _onTapBranch(0),
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.calendar_today_outlined,
                      activeIcon: Icons.calendar_today_rounded,
                      label: 'Bookings',
                      isActive: navigationShell.currentIndex == 2,
                      onTap: () => _onTapBranch(2),
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.alt_route_rounded,
                      label: 'Trip',
                      isActive: navigationShell.currentIndex == 3,
                      onTap: () => _onTapBranch(3),
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.bolt_outlined,
                      activeIcon: Icons.bolt_rounded,
                      label: 'Charging',
                      isActive: navigationShell.currentIndex == 4,
                      onTap: () => _onTapBranch(4),
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      isActive: navigationShell.currentIndex == 1,
                      onTap: () => _onTapBranch(1),
                    ),
                  ],
                ),
              ),
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
    required BuildContext context,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    final ui = AppUiColors.of(context);
    final itemColor = isActive ? ui.navActive : ui.navInactive;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isActive ? ui.navSelectedBackground : AppColors.transparentColor,
            borderRadius: BorderRadius.circular(26.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: itemColor,
                size: 22.sp,
              ),
              2.verticalSpace,
              AppText(
                label,
                color: itemColor,
                fontSize: FontSizes.font10Sp,
                fontWeight:
                    isActive ? FontWeights.weight600 : FontWeights.weight400,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
