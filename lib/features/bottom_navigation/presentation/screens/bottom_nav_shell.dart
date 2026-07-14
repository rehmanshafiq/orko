import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';

/// Shell screen that wraps the bottom navigation bar.
/// Uses [StatefulShellRoute] from go_router for nested navigation,
/// preserving each tab's navigation stack independently.
class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  /// Branch index of the Bookings tab.
  static const int bookingsBranchIndex = 2;

  /// Branch index of the Profile (account) tab.
  static const int accountBranchIndex = 1;

  /// Bumped every time the Bookings tab is tapped, so the screen is rebuilt and
  /// always lands on the Active tab (see MyBookingsPage) instead of the sub-tab
  /// the user last left selected.
  static final ValueNotifier<int> bookingsRefreshTick = ValueNotifier<int>(0);

  /// Bumped every time the Profile tab is tapped, so the screen is rebuilt and
  /// always lands on the Profile sub-tab instead of Vehicles/Settings the user
  /// last left selected.
  static final ValueNotifier<int> accountRefreshTick = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        // Use viewPadding instead of padding so the bottom inset survives even
        // when something (keyboard, ancestor) consumes MediaQuery.padding,
        // keeping the bar clear of the system navigation / home indicator.
        maintainBottomViewPadding: true,
        child: Padding(
          padding: AppUtils.bottomNavOuterPadding,
          child: CustomPaint(
            painter: _NavBarBackgroundPainter(
              fill: ui.bottomNavContainerBg,
              border: ui.borderMuted,
              shadow: ui.bottomNavShadow,
            ),
            child: Container(
              height: 64.h,
              padding: AppUtils.bottomNavInnerPadding,
              child: Row(
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.map_outlined,
                    label: 'Map',
                    isActive: navigationShell.currentIndex == 0,
                    onTap: () => _onTapBranch(0),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Bookings',
                    isActive: navigationShell.currentIndex == 2,
                    onTap: () => _onTapBranch(2),
                  ),
                  // Gap under the pinched "neck" of the bar outline.
                  SizedBox(width: _NavBarBackgroundPainter.centerGap),
                  _buildNavItem(
                    context: context,
                    icon: Icons.alt_route_rounded,
                    label: 'Trip',
                    isActive: navigationShell.currentIndex == 3,
                    onTap: () => _onTapBranch(3),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
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
    );
  }

  void _onTapBranch(int index) {
    // Always rebuild Bookings so it reopens on the Active tab.
    if (index == bookingsBranchIndex) {
      bookingsRefreshTick.value++;
    }
    // Always rebuild Profile so it reopens on the Profile sub-tab.
    if (index == accountBranchIndex) {
      accountRefreshTick.value++;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    final ui = AppUiColors.of(context);
    final Color itemColor = isActive ? ui.navActive : ui.navInactive;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isActive,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ui.bottomNavItemBg,
                border: Border.all(
                  color: isActive ? ui.navActive : ui.bottomNavBorder,
                ),
              ),
              child: Icon(icon, color: itemColor, size: 23),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the nav bar background: two capsule lobes joined by a smooth
/// concave "neck" at the horizontal center, matching the gooey pill design.
class _NavBarBackgroundPainter extends CustomPainter {
  final Color fill;
  final Color border;
  final Color shadow;

  _NavBarBackgroundPainter({
    required this.fill,
    required this.border,
    required this.shadow,
  });

  /// Total width of the pinched neck region at the bar's center.
  static double get neckWidth => 56.w;

  /// Spacer between the two icon pairs — narrower than the neck itself so the
  /// groups sit closer together while the curve keeps its full sweep.
  static double get centerGap => 36.w;

  /// How far the top/bottom edges dip inward at the center.
  static double get _neckDepth => 16.h;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    final shadowPaint = Paint()
      ..color = shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = h / 2;
    final cx = w / 2;
    final nw = neckWidth / 2;
    final nd = _neckDepth;

    return Path()
      // Top edge, left lobe → neck dip → right lobe.
      ..moveTo(r, 0)
      ..lineTo(cx - nw, 0)
      ..cubicTo(cx - nw * 0.45, 0, cx - nw * 0.55, nd, cx, nd)
      ..cubicTo(cx + nw * 0.55, nd, cx + nw * 0.45, 0, cx + nw, 0)
      ..lineTo(w - r, 0)
      // Right rounded cap.
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      // Bottom edge, mirrored neck dip.
      ..lineTo(cx + nw, h)
      ..cubicTo(cx + nw * 0.45, h, cx + nw * 0.55, h - nd, cx, h - nd)
      ..cubicTo(cx - nw * 0.55, h - nd, cx - nw * 0.45, h, cx - nw, h)
      ..lineTo(r, h)
      // Left rounded cap.
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();
  }

  @override
  bool shouldRepaint(_NavBarBackgroundPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.border != border ||
      oldDelegate.shadow != shadow;
}
