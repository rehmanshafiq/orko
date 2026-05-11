import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.ui,
    required this.durationHours,
    required this.minDurationHours,
    required this.maxDurationHours,
    required this.onDecrease,
    required this.onIncrease,
  });

  final AppUiColors ui;
  final int durationHours;
  final int minDurationHours;
  final int maxDurationHours;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final canDecrease = durationHours > minDurationHours;
    final canIncrease = durationHours < maxDurationHours;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          'Duration',
          color: ui.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight700,
        ),
        Row(
          children: [
            _RoundIconButton(
              ui: ui,
              icon: Icons.remove,
              enabled: canDecrease,
              onTap: onDecrease,
            ),
            10.horizontalSpace,
            AppText(
              durationHours == 1 ? '1 hour' : '$durationHours hours',
              color: ui.textPrimary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
            10.horizontalSpace,
            _RoundIconButton(
              ui: ui,
              icon: Icons.add,
              enabled: canIncrease,
              onTap: onIncrease,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.ui,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final AppUiColors ui;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: ui.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? ui.textPrimary.withValues(alpha: 0.18)
                  : ui.borderSubtle,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: ui.textPrimary.withValues(alpha: enabled ? 0.92 : 0.35),
              size: 12.sp,
            ),
          ),
        ),
      ),
    );
  }
}
