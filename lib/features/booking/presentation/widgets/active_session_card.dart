import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';

/// Card shown under the "Active" tab when a charging session is running, built
/// from `GET api/v1/bookings/live-session/`.
///
/// Every figure is rendered defensively — the SOC/energy/cost fields stay null
/// until the backend computes them mid-session.
class ActiveSessionCard extends StatelessWidget {
  const ActiveSessionCard({
    super.key,
    required this.ui,
    required this.session,
  });

  final AppUiColors ui;
  final LiveSessionEntity session;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ui.brandPrimary, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44.r,
                width: 44.r,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: ui.brandPrimary, width: 1.5),
                ),
                child: Icon(Icons.bolt, color: ui.brandPrimary, size: 22.sp),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      session.displayName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font16Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_startedAtLabel != null) ...[
                      4.verticalSpace,
                      AppText(
                        'Started $_startedAtLabel',
                        color: ui.textSecondary,
                        fontSize: FontSizes.font12Sp,
                        fontWeight: FontWeights.weight400,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              8.horizontalSpace,
              const _LiveBadge(),
            ],
          ),
          if (_elapsedLabel != null) ...[
            16.verticalSpace,
            Row(
              children: [
                Icon(Icons.timer_outlined, color: ui.brandPrimary, size: 16.sp),
                6.horizontalSpace,
                Expanded(
                  child: AppText(
                    'Charging for $_elapsedLabel',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          ..._buildMetrics(),
        ],
      ),
    );
  }

  List<Widget> _buildMetrics() {
    final currency = session.currency ?? 'PKR';
    // Prefer the richer live-telemetry fields; fall back to the leaner payload.
    final energy = session.energyDeliveredKwh ?? session.kwhDelivered;
    final soc = session.currentChargePercentage ?? session.endSoc;
    final cost = session.currentCost ?? session.totalCost;

    final metrics = <_Metric>[
      if (energy != null) _Metric('Energy', '${_trim(energy)} kWh'),
      if (session.chargingSpeedKw != null)
        _Metric('Speed', '${_trim(session.chargingSpeedKw!)} kW'),
      if (session.startSoc != null)
        _Metric('Start SOC', '${_trim(session.startSoc!)}%'),
      if (soc != null) _Metric('Current SOC', '${_trim(soc)}%'),
      if (session.timeLeft != null && session.timeLeft!.trim().isNotEmpty)
        _Metric('Time left', session.timeLeft!.trim()),
      if (session.energyCost != null)
        _Metric('Energy cost', AppHelpers.formatCurrency(session.energyCost!)),
      if (cost != null)
        _Metric('Total', AppHelpers.formatCurrency(cost, currency: currency)),
    ];

    if (metrics.isEmpty) return const [];

    return [
      14.verticalSpace,
      Divider(color: ui.borderSubtle, height: 1),
      14.verticalSpace,
      Wrap(
        spacing: 28.w,
        runSpacing: 14.h,
        children: [
          for (final m in metrics)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  m.label,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font11Sp,
                  fontWeight: FontWeights.weight400,
                ),
                4.verticalSpace,
                AppText(
                  m.value,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ],
            ),
        ],
      ),
    ];
  }

  /// Human-readable session duration, preferring the live `session_time`
  /// figure and falling back to `elapsed`. Null when neither is present.
  String? get _elapsedLabel {
    final time = session.sessionTime?.trim();
    if (time != null && time.isNotEmpty) return time;
    final elapsed = session.elapsed?.trim();
    if (elapsed != null && elapsed.isNotEmpty) return elapsed;
    return null;
  }

  /// `2026-05-05 19:33:32` → `MMM d, yyyy · h:mm a`, falling back to the raw
  /// string (or null) when it can't be parsed.
  String? get _startedAtLabel {
    final raw = session.startedAt;
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy · h:mm a').format(parsed);
  }

  /// Drops a trailing `.0` so `0.45` stays but `12.0` shows as `12`.
  String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _Metric {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(width: 1.w, color: ui.brandPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7.r,
            width: 7.r,
            decoration: BoxDecoration(
              color: ui.brandPrimary,
              shape: BoxShape.circle,
            ),
          ),
          6.horizontalSpace,
          AppText(
            'LIVE',
            color: ui.brandPrimary,
            fontSize: FontSizes.font11Sp,
            fontWeight: FontWeights.weight700,
          ),
        ],
      ),
    );
  }
}
