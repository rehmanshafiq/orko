import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';

class ChargingStatusMobileView extends StatelessWidget {
  const ChargingStatusMobileView({super.key});

  static const Color _bgColor = Color(0xFFF8F9FA);
  static const Color _primaryGreen = Color(0xFF006D44);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _stopRed = Color(0xFFC62828);
  static const Color _mintIconBg = Color(0xFFD1FAE5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
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
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.shimmerGreyColor,
          child: Icon(
            Icons.person_rounded,
            color: ChargingStatusMobileView._textMuted,
            size: 22.sp,
          ),
        ),
        Expanded(
          child: Center(
            child: AppText(
              'HUBCO',
              color: ChargingStatusMobileView._primaryGreen,
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
            color: ChargingStatusMobileView._primaryGreen,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'CURRENT STATION',
          color: ChargingStatusMobileView._textMuted,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight700,
          letterSpacing: 1.2,
        ),
        6.verticalSpace,
        AppText(
          stationName,
          color: ChargingStatusMobileView._textDark,
          fontSize: FontSizes.font26Sp,
          fontWeight: FontWeights.weight700,
        ),
        10.verticalSpace,
        Row(
          children: [
            Container(
              width: 8.w,
              height: 8.w,
              decoration: const BoxDecoration(
                color: Color(0xFF6EE7B7),
                shape: BoxShape.circle,
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: AppText(
                sessionLabel,
                color: ChargingStatusMobileView._textMuted,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BatteryGauge extends StatelessWidget {
  const _BatteryGauge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final progress = (percent / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: 220.h,
      child: Center(
        child: SizedBox(
          width: 200.w,
          height: 200.w,
          child: CustomPaint(
            painter: _BatteryGaugePainter(progress: progress),
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
                        color: ChargingStatusMobileView._primaryGreen,
                        fontSize: FontSizes.font36Sp,
                        fontWeight: FontWeights.weight700,
                        height: 1,
                      ),
                      AppText(
                        '%',
                        color: ChargingStatusMobileView._primaryGreen,
                        fontSize: FontSizes.font18Sp,
                        fontWeight: FontWeights.weight600,
                        height: 1.4,
                      ),
                    ],
                  ),
                  6.verticalSpace,
                  AppText(
                    'BATTERY LEVEL',
                    color: ChargingStatusMobileView._primaryGreen,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight700,
                    letterSpacing: 1.1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatteryGaugePainter extends CustomPainter {
  _BatteryGaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = AppColors.shimmerGreyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = ChargingStatusMobileView._primaryGreen
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
    return oldDelegate.progress != progress;
  }
}

class _StopChargingButton extends StatelessWidget {
  const _StopChargingButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChargingStatusMobileView._stopRed,
          foregroundColor: AppColors.whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(Icons.stop_circle_outlined, size: 22.sp),
        label: AppText(
          'Stop Charging',
          color: AppColors.whiteColor,
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_outlined,
                label: 'ESTIMATED COST',
                value: _formatCost(state.cost),
                valueColor: ChargingStatusMobileView._textDark,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: _MetricCard(
                icon: Icons.bolt_rounded,
                label: 'ENERGY DELIVERED',
                value: '${state.energyDelivered} ${state.energyDeliveredUnit}',
                valueColor: ChargingStatusMobileView._textDark,
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
                valueColor: ChargingStatusMobileView._primaryGreen,
                labelColor: ChargingStatusMobileView._primaryGreen,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: _MetricCard(
                icon: Icons.access_time_rounded,
                label: 'SESSION TIME',
                value: state.sessionTime,
                valueColor: ChargingStatusMobileView._textDark,
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
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.05),
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
            color: labelColor ?? ChargingStatusMobileView._textMuted,
          ),
          10.verticalSpace,
          AppText(
            label,
            color: labelColor ?? ChargingStatusMobileView._textMuted,
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
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.05),
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
              color: ChargingStatusMobileView._mintIconBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.ev_station_rounded,
              color: ChargingStatusMobileView._primaryGreen,
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
                  color: ChargingStatusMobileView._textDark,
                  fontSize: FontSizes.font15Sp,
                  fontWeight: FontWeights.weight700,
                ),
                4.verticalSpace,
                AppText(
                  'Connector #02 · DC Fast',
                  color: ChargingStatusMobileView._textMuted,
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
                color: ChargingStatusMobileView._textMuted,
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight700,
                letterSpacing: 0.5,
              ),
              4.verticalSpace,
              AppText(
                '395V',
                color: ChargingStatusMobileView._textDark,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004D40),
            Color(0xFF006D44),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'ECO CONTRIBUTION',
            color: AppColors.whiteColor.withValues(alpha: 0.85),
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
            letterSpacing: 1.2,
          ),
          10.verticalSpace,
          AppText(
            "You've offset 18.4 kg of CO₂ this session — equivalent to planting 2 trees.",
            color: AppColors.whiteColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            height: 1.45,
          ),
        ],
      ),
    );
  }
}
