import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

/// Square icon button used in the home top bar (search's filter icon and the
/// notification bell). [isCompact] renders the smaller in-search-field variant;
/// [isPrimary] outlines it with the brand color.
class TopActionIconWidget extends StatelessWidget {
  const TopActionIconWidget(
    this.icon, {
    super.key,
    this.isPrimary = false,
    this.isCompact = false,
    this.compactSize = 31,
    this.onTap,
  });

  final IconData icon;
  final bool isPrimary;
  final bool isCompact;

  /// Side length (logical px, pre-`.h`/`.w`) of the compact variant. Defaults
  /// to the home top-bar size; the filter screen overrides it to 34.
  final double compactSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final radius = BorderRadius.circular(8.r);
    final child = Container(
      height: isCompact ? compactSize.h : 52.h,
      width: isCompact ? compactSize.w : 52.w,
      decoration: BoxDecoration(
        color: ui.searchBackground,
        borderRadius: radius,
        border: Border.all(
          color: isPrimary ? ui.brandPrimary : ui.borderSubtle,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: isCompact ? 15 : 26,
        color: ui.textMuted,
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: child,
      ),
    );
  }
}
