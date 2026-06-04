import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_summary_metric_widget.dart';

class TripSummaryCardWidget extends StatelessWidget {
  const TripSummaryCardWidget({
    required this.plan,
    required this.formatDuration,
    required this.formatPkr,
    this.isMapView = true,
    this.onViewModeChanged,
    super.key,
  });

  final TripPlanModel? plan;
  final String Function(Duration) formatDuration;
  final String Function(int) formatPkr;
  final bool isMapView;
  final ValueChanged<bool>? onViewModeChanged;

  String _formatTotalTime(Duration duration) {
    final formatted = formatDuration(duration);
    if (formatted.endsWith('m') && !formatted.endsWith('min')) {
      return '${formatted.substring(0, formatted.length - 1)}min';
    }
    return formatted;
  }

  String _formatChargingCost(int amount) {
    final formatted = formatPkr(amount);
    if (formatted.startsWith('PKR ')) {
      return 'Rs ${formatted.substring(4)}';
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.transparentColor,
            // borderRadius: BorderRadius.circular(16.r),
            // border: Border.all(color: ui.borderSubtle),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TripSummaryMetricWidget(
                    icon: Icons.add_location_alt_outlined,
                    label: 'Total Distance:',
                    value: plan == null ? '—' : '${plan!.distanceKm.round()} km',
                  ),
                ),
                _SummarySectionDivider(color: ui.borderSubtle),
                Expanded(
                  child: TripSummaryMetricWidget(
                    icon: Icons.schedule_rounded,
                    label: 'Total Time:',
                    value: plan == null ? '—' : _formatTotalTime(plan!.duration),
                  ),
                ),
                _SummarySectionDivider(color: ui.borderSubtle),
                Expanded(
                  child: TripSummaryMetricWidget(
                    icon: Icons.payments_outlined,
                    label: 'Total Charging Cost:',
                    value: plan == null ? '—' : _formatChargingCost(plan!.costPkr),
                  ),
                ),
              ],
            ),
          ),
        ),
        8.verticalSpace,
        _TripSummaryViewToggle(
          isMapView: isMapView,
          onChanged: onViewModeChanged,
        ),
      ],
    );
  }
}

class _SummarySectionDivider extends StatelessWidget {
  const _SummarySectionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      color: color,
    );
  }
}

class _TripSummaryViewToggle extends StatefulWidget {
  const _TripSummaryViewToggle({
    required this.isMapView,
    this.onChanged,
  });

  final bool isMapView;
  final ValueChanged<bool>? onChanged;

  @override
  State<_TripSummaryViewToggle> createState() => _TripSummaryViewToggleState();
}

class _TripSummaryViewToggleState extends State<_TripSummaryViewToggle> {
  late bool _isMapView;

  @override
  void initState() {
    super.initState();
    _isMapView = widget.isMapView;
  }

  @override
  void didUpdateWidget(covariant _TripSummaryViewToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMapView != widget.isMapView) {
      _isMapView = widget.isMapView;
    }
  }

  void _setMapView(bool value) {
    setState(() => _isMapView = value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final activeColor = ui.brandPrimary;
    final inactiveColor = ui.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _setMapView(true),
          child: AppText(
            'Map View',
            color: _isMapView ? activeColor : inactiveColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight600,
          ),
        ),
        12.horizontalSpace,
        _SummaryViewSwitch(
          isMapView: _isMapView,
          onChanged: _setMapView,
        ),
        12.horizontalSpace,
        GestureDetector(
          onTap: () => _setMapView(false),
          child: AppText(
            'List View',
            color: _isMapView ? inactiveColor : activeColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight600,
          ),
        ),
      ],
    );
  }
}

class _SummaryViewSwitch extends StatelessWidget {
  const _SummaryViewSwitch({
    required this.isMapView,
    required this.onChanged,
  });

  final bool isMapView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final trackColor = ui.brandSecondary.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: () => onChanged(!isMapView),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44.w,
        height: 24.h,
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: isMapView ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ui.brandLightGreen,
                  ui.brandDarkGreen,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
