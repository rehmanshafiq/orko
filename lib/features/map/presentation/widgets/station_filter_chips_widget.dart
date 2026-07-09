import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Horizontally-scrollable chip row shared by the home "Nearby Stations" sheet
/// and the filter results sheet: an "Available Now" toggle plus (disabled) one
/// chip per connector [types] value.
class StationFilterChipsWidget extends StatelessWidget {
  const StationFilterChipsWidget({
    super.key,
    required this.types,
    required this.availableNowSelected,
    required this.selectedTypes,
    required this.onToggleAvailableNow,
    required this.onToggleType,
  });

  final List<String> types;
  final bool availableNowSelected;
  final Set<String> selectedTypes;
  final VoidCallback onToggleAvailableNow;
  final ValueChanged<String> onToggleType;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _FilterChip(
        'Available Now',
        isActive: availableNowSelected,
        onTap: onToggleAvailableNow,
      ),
      // for (final type in types)
      //   _FilterChip(
      //     type,
      //     isActive: selectedTypes.contains(type),
      //     onTap: () => onToggleType(type),
      //   ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) 8.horizontalSpace,
            chips[i],
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.text, {this.isActive = false, this.onTap});

  final String text;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: AppUtils.homeFilterChipPadding,
      decoration: BoxDecoration(
        color: isActive
            ? ui.brandPrimary.withValues(alpha: 0.12)
            : ui.innerCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isActive ? ui.brandPrimary : ui.borderSubtle),
      ),
      child: AppText(
        text,
        color: ui.textPrimary.withValues(alpha: 0.8),
        fontSize: FontSizes.font14Sp,
        fontWeight: isActive ? FontWeights.weight600 : FontWeights.weight400,
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }
}
