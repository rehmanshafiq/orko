import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_revamped_theme.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';

class ChargingStatusMobileView extends StatelessWidget {
  const ChargingStatusMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Scaffold(
      backgroundColor: t.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<ChargingStatusCubit, ChargingStatusState>(
          builder: (context, state) {
            final cubit = context.read<ChargingStatusCubit>();
            final batteryPercent = state.chargingPercentage.round();

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              children: [
                8.verticalSpace,
                _StatusHeader(onSearch: () => context.push('/search')),
                24.verticalSpace,
                _StationInfoSection(
                  stationName: _stationDisplayName(state.stationHeadline),
                  sessionLabel: _sessionDisplayLabel(state),
                ),
                28.verticalSpace,
                _BatteryGauge(percent: batteryPercent),
                28.verticalSpace,
                _StopChargingButton(onPressed: cubit.stopCharging),
                24.verticalSpace,
                _MetricsGrid(state: state),
                16.verticalSpace,
                const _ChargerDetailsCard(),
                16.verticalSpace,
                const _EcoContributionCard(),
                24.verticalSpace,
              ],
            );
          },
        ),
      ),
    );
  }

  static String _stationDisplayName(String headline) {
    if (headline.contains('Gulberg')) return headline;
    return 'Gulberg Premium Hub III';
  }

  static String _sessionDisplayLabel(ChargingStatusState state) {
    if (state.status == ChargingSessionStatus.emergency) {
      return 'Emergency Stop Active';
    }
    if (state.status == ChargingSessionStatus.idle) {
      return 'Session Ended';
    }
    return 'Active Session: CCS2-DC Fast';
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: t.avatarBackground,
          child: Icon(
            Icons.person_rounded,
            color: t.textMuted,
            size: 22.sp,
          ),
        ),
        Expanded(
          child: Center(
            child: AppText(
              'HUBCO',
              color: t.chargingStatusPrimaryGreen,
              fontSize: FontSizes.font22Sp,
              fontWeight: FontWeights.weight700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        IconButton(
          onPressed: onSearch,
          icon: Icon(
            Icons.search_rounded,
            color: t.chargingStatusPrimaryGreen,
            size: 24.sp,
          ),
        ),
      ],
    );
  }
}

class _StationInfoSection extends StatelessWidget {
  const _StationInfoSection({
    required this.stationName,
    required this.sessionLabel,
  });

  final String stationName;
  final String sessionLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText(
            'CURRENT STATION',
            color: t.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
            letterSpacing: 1.2,
            textAlign: TextAlign.center,
          ),
          6.verticalSpace,
          AppText(
            stationName,
            color: t.textPrimary,
            fontSize: FontSizes.font20Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
          ),
          10.verticalSpace,
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: t.sessionActiveDot,
                  shape: BoxShape.circle,
                ),
              ),
              8.horizontalSpace,
              AppText(
                sessionLabel,
                color: t.textMuted,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryGauge extends StatelessWidget {
  const _BatteryGauge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final progress = (percent / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: 220.h,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.isLight ? t.cardBackground : null,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 220.w,
            height: 220.w,
            child: CustomPaint(
              painter: _BatteryGaugePainter(progress: progress, theme: t),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '$percent',
                          color: t.chargingStatusPrimaryGreen,
                          fontSize: FontSizes.font44Sp,
                          fontWeight: FontWeights.weight700,
                          height: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: AppText(
                            '%',
                            color: t.chargingStatusPrimaryGreen,
                            fontSize: FontSizes.font12Sp,
                            fontWeight: FontWeights.weight400,
                            height: 2,
                          ),
                        ),
                      ],
                    ),
                    6.verticalSpace,
                    AppText(
                      'BATTERY LEVEL',
                      color: t.chargingStatusPrimaryGreen,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight400,
                      letterSpacing: 1.1,
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
}

class _BatteryGaugePainter extends CustomPainter {
  _BatteryGaugePainter({required this.progress, required this.theme});

  final double progress;
  final AppRevampedTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = theme.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = theme.chargingStatusPrimaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}

class _StopChargingButton extends StatelessWidget {
  const _StopChargingButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: t.stopRed,
          foregroundColor: t.textOnBrand,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(Icons.stop_circle_outlined, size: 22.sp),
        label: AppText(
          'Stop Charging',
          color: t.textOnBrand,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.state});

  final ChargingStatusState state;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_outlined,
                label: 'ESTIMATED COST',
                value: _formatCost(state.cost),
                valueColor: t.textPrimary,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: _MetricCard(
                icon: Icons.bolt_rounded,
                label: 'ENERGY DELIVERED',
                value: '${state.energyDelivered} ${state.energyDeliveredUnit}',
                valueColor: t.textPrimary,
              ),
            ),
          ],
        ),
        12.verticalSpace,
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.speed_rounded,
                label: 'CURRENT SPEED',
                value: '${state.chargingSpeed} ${state.chargingSpeedUnit}',
                valueColor: t.chargingStatusPrimaryGreen,
                labelColor: t.chargingStatusPrimaryGreen,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: _MetricCard(
                icon: Icons.access_time_rounded,
                label: 'SESSION TIME',
                value: state.sessionTime,
                valueColor: t.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatCost(String cost) {
    if (cost.startsWith('PKR')) return cost;
    if (cost.startsWith('Rs')) {
      return cost.replaceFirst('Rs', 'PKR');
    }
    return 'PKR $cost';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: labelColor ?? t.textMuted,
          ),
          10.verticalSpace,
          AppText(
            label,
            color: labelColor ?? t.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
            letterSpacing: 0.6,
            maxLines: 2,
          ),
          8.verticalSpace,
          AppText(
            value,
            color: valueColor,
            fontSize: FontSizes.font15Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChargerDetailsCard extends StatelessWidget {
  const _ChargerDetailsCard();

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: t.mintIconBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.ev_station_rounded,
              color: t.chargingStatusPrimaryGreen,
              size: 26.sp,
            ),
          ),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Supernova 150kW',
                  color: t.textPrimary,
                  fontSize: FontSizes.font15Sp,
                  fontWeight: FontWeights.weight700,
                ),
                4.verticalSpace,
                AppText(
                  'Connector #02 · DC Fast',
                  color: t.textMuted,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                'VOLTAGE',
                color: t.textMuted,
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight700,
                letterSpacing: 0.5,
              ),
              4.verticalSpace,
              AppText(
                '395V',
                color: t.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EcoContributionCard extends StatelessWidget {
  const _EcoContributionCard();

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.ecoGradientStart,
            t.chargingStatusPrimaryGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'ECO CONTRIBUTION',
            color: t.textOnBrand.withValues(alpha: 0.85),
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
            letterSpacing: 1.2,
          ),
          10.verticalSpace,
          AppText(
            "You've offset 18.4 kg of CO₂ this session — equivalent to planting 2 trees.",
            color: t.textOnBrand,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            height: 1.45,
          ),
        ],
      ),
    );
  }
}
