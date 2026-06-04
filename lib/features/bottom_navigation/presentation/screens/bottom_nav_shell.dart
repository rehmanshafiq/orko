import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Shell screen that wraps the bottom navigation bar.
///
/// Uses [PersistentTabView.router] from `persistent_bottom_nav_bar_v2`, wired to
/// go_router's [StatefulShellRoute] so each tab keeps its own navigation stack.
/// The visual nav bar is supplied via a custom [navBarBuilder] that matches the
/// app design (icon above label, pill behind the active tab, rounded top
/// corners).
///
/// IMPORTANT: the tab order here must match the branch order declared in
/// `AppRouter` — PersistentTabView.router maps tab index → branch index 1:1.
class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    return PersistentTabView.router(
      navigationShell: navigationShell,
      // Shown behind the rounded top corners of the nav bar.
      backgroundColor: ui.scaffoldBackground,
      // Let the tab content extend under the nav bar so the rounded top
      // corners reveal the screen behind them instead of a flat fill.
      navBarOverlap: const NavBarOverlap.full(),
      tabs: _tabs(ui),
      navBarBuilder: (navBarConfig) => DecoratedNavBar(
        decoration: NavBarDecoration(
          color: ui.bottomNavContainerBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.r),
            topRight: Radius.circular(32.r),
          ),
          padding: AppUtils.bottomNavInnerPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < navBarConfig.items.length; i++)
              _buildNavItem(navBarConfig, i),
          ],
        ),
      ),
    );
  }

  /// Tab definitions. Order MUST match the branches in `AppRouter`.
  List<PersistentRouterTabConfig> _tabs(AppUiColors ui) => [
        _tab(ui, Icons.map_rounded, Icons.map_outlined, 'Map'),
        _tab(ui, Icons.calendar_today_rounded, Icons.calendar_today_outlined,
            'Bookings'),
        _tab(ui, Icons.alt_route_rounded, Icons.alt_route_rounded, 'Trip'),
        _tab(ui, Icons.bolt_rounded, Icons.bolt_outlined, 'Charging'),
        _tab(ui, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
      ];

  PersistentRouterTabConfig _tab(
    AppUiColors ui,
    IconData activeIcon,
    IconData inactiveIcon,
    String title,
  ) =>
      PersistentRouterTabConfig(
        item: ItemConfig(
          icon: Icon(activeIcon),
          inactiveIcon: Icon(inactiveIcon),
          title: title,
          activeForegroundColor: ui.navActive,
          inactiveForegroundColor: ui.navInactive,
          activeColorSecondary: ui.navSelectedBackground,
        ),
      );

  Widget _buildNavItem(NavBarConfig config, int index) {
    final item = config.items[index];
    final isActive = config.selectedIndex == index;
    final itemColor =
        isActive ? item.activeForegroundColor : item.inactiveForegroundColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => config.onItemSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isActive
                ? item.activeBackgroundColor
                : AppColors.transparentColor,
            borderRadius: BorderRadius.circular(26.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(color: itemColor, size: 22.sp),
                child: isActive ? item.icon : item.inactiveIcon,
              ),
              2.verticalSpace,
              AppText(
                item.title ?? '',
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
