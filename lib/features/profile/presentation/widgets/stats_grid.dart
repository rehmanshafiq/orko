import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_state.dart';

/// Trims a trailing `.0` (40.0 → "40", 40.8 → "40.8").
String _trimNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}

/// Groups an integer with thousands separators (5930 → "5,930").
String _grouped(num v) {
  final s = v.toInt().toString();
  final neg = s.startsWith('-');
  final digits = neg ? s.substring(1) : s;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return neg ? '-$buf' : buf.toString();
}

/// Charging stats grid backed by `charging_stats`. Shows per-tile spinners
/// while loading, dashes + a retry affordance on failure, and zeroed values
/// for guests / brand-new accounts.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return BlocBuilder<ChargingStatsCubit, ChargingStatsState>(
      builder: (context, state) {
        final stats = state.stats;
        final loading = state.isLoading && stats == null;
        final failed = state.isFailure && stats == null;

        final charges = stats != null ? _grouped(stats.totalCharges) : '—';
        final kwh = stats != null ? _trimNum(stats.totalKwh) : '—';
        final money =
            stats != null ? 'PKR ${_grouped(stats.moneySavedPkr)}' : '—';
        final co2 =
            stats != null ? '${_trimNum(stats.co2ReducedKg)} kg' : '—';

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.bolt_rounded,
                    iconBg: AppColors.transparentColor,
                    iconColor: ui.brandSecondary,
                    value: charges,
                    valueColor: ui.textPrimary,
                    label: 'Total Charging Sessions',
                    isLoading: loading,
                    valueLeftPadding: 4.0,
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: StatTile(
                    icon: Icons.battery_charging_full_rounded,
                    iconBg: AppColors.transparentColor,
                    iconColor: ui.brandSecondary,
                    value: kwh,
                    valueColor: ui.textPrimary,
                    label: 'kWh Charged',
                    isLoading: loading,
                  ),
                ),
              ],
            ),
            10.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.trending_up_rounded,
                    iconBg: AppColors.transparentColor,
                    iconColor: ui.brandSecondary,
                    value: money,
                    valueColor: ui.textPrimary,
                    label: 'Money Saved',
                    isLoading: loading,
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: StatTile(
                    icon: Icons.eco_outlined,
                    iconBg: AppColors.transparentColor,
                    iconColor: ui.brandSecondary,
                    value: co2,
                    valueColor: ui.textPrimary,
                    label: 'CO2 Reduced',
                    isLoading: loading,
                  ),
                ),
              ],
            ),
            if (failed) ...[
              8.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 14.r, color: ui.textSecondary),
                  6.horizontalSpace,
                  Flexible(
                    child: AppText(
                      state.error ?? 'Couldn\'t load your stats.',
                      color: ui.textSecondary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  10.horizontalSpace,
                  GestureDetector(
                    onTap: () => context.read<ChargingStatsCubit>().load(),
                    behavior: HitTestBehavior.opaque,
                    child: AppText(
                      'Retry',
                      color: ui.brandPrimary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    this.isLoading = false,
    this.valueLeftPadding = 0,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;

  /// When true, a small spinner replaces the value while stats load.
  final bool isLoading;

  /// Left inset applied to the value only (used to nudge a specific tile).
  final double valueLeftPadding;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.vehicleImagePlaceholder,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift left by the icon glyph's built-in optical padding so its
          // visible edge lines up flush with the value/label text below.
          Transform.translate(
            offset: Offset(-2.r, 0),
            child: Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24.r),
            ),
          ),
          10.verticalSpace,
          SizedBox(
            height: 24.h,
            child: Padding(
              padding: EdgeInsets.only(left: valueLeftPadding),
              child: isLoading
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ui.brandPrimary,
                        ),
                      ),
                    )
                  : AppText(
                      value,
                      color: valueColor,
                      fontSize: FontSizes.font18Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
          4.verticalSpace,
          AppText(
            label,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
        ],
      ),
    );
  }
}
