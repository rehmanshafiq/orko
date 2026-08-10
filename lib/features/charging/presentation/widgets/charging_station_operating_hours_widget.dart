import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';

/// Renders the station's weekly opening hours from `operating_hours`:
/// an Open/Closed badge for today, the collapsed `grouped` timings, and an
/// expandable full-week view (`days`). Falls back to [fallbackText] when the
/// backend supplies no structured hours.
class ChargingStationOperatingHoursWidget extends StatefulWidget {
  const ChargingStationOperatingHoursWidget({
    super.key,
    required this.info,
    required this.fallbackText,
  });

  final StationOperatingHoursEntity? info;

  /// Legacy single-line hours shown when [info] is null/empty.
  final String fallbackText;

  @override
  State<ChargingStationOperatingHoursWidget> createState() =>
      _ChargingStationOperatingHoursWidgetState();
}

class _ChargingStationOperatingHoursWidgetState extends State<ChargingStationOperatingHoursWidget> {
  bool _showFullWeek = false;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final info = widget.info;

    // No structured hours — fall back to the legacy today's-hours string.
    if (info == null || info.grouped.isEmpty) {
      return AppText(
        widget.fallbackText.isNotEmpty ? widget.fallbackText : 'Not available',
        color: ui.textSecondary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight400,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.today != null) ...[
          _TodayStatus(ui: ui, today: info.today!),
          12.verticalSpace,
        ],
        for (var i = 0; i < info.grouped.length; i++) ...[
          if (i > 0) 8.verticalSpace,
          _HoursRow(
            ui: ui,
            label: info.grouped[i].daysLabel,
            value: info.grouped[i].isClosed
                ? 'Closed'
                : _range(info.grouped[i].openingTime, info.grouped[i].closingTime),
            closed: info.grouped[i].isClosed,
          ),
        ],
        if (info.days.isNotEmpty) ...[
          10.verticalSpace,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showFullWeek = !_showFullWeek),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  _showFullWeek ? 'Hide full week' : 'View full week',
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight700,
                ),
                2.horizontalSpace,
                Icon(
                  _showFullWeek
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: ui.textSecondary,
                  size: 18.sp,
                ),
              ],
            ),
          ),
          if (_showFullWeek) ...[
            10.verticalSpace,
            for (var i = 0; i < info.days.length; i++) ...[
              if (i > 0) 8.verticalSpace,
              _HoursRow(
                ui: ui,
                label: info.days[i].dayName,
                value: info.days[i].isClosed
                    ? 'Closed'
                    : _range(info.days[i].openingTime, info.days[i].closingTime),
                closed: info.days[i].isClosed,
                highlight: info.days[i].isToday,
              ),
            ],
          ],
        ],
      ],
    );
  }
}

/// The Open/Closed pill for today plus today's range.
class _TodayStatus extends StatelessWidget {
  const _TodayStatus({required this.ui, required this.today});

  final AppUiColors ui;
  final StationOperatingDay today;

  @override
  Widget build(BuildContext context) {
    final open = !today.isClosed;
    final accent = open ? ui.brandPrimary : AppColors.redColor;
    final rangeText = open ? _range(today.openingTime, today.closingTime) : 'Closed today';

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: accent),
          ),
          child: AppText(
            open ? 'Open' : 'Closed',
            color: accent,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: AppText(
            rangeText.isEmpty ? 'Today' : rangeText,
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ),
      ],
    );
  }
}

/// A label → value row (days label / day name on the left, hours on the right).
class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.ui,
    required this.label,
    required this.value,
    this.closed = false,
    this.highlight = false,
  });

  final AppUiColors ui;
  final String label;
  final String value;
  final bool closed;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final labelColor = highlight ? ui.brandPrimary : ui.textSecondary;
    final valueColor = closed ? AppColors.redColor : (highlight ? ui.brandPrimary : ui.textPrimary);
    final weight = FontWeights.weight500; //highlight ? FontWeights.weight700 :

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppText(
            label,
            color: labelColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: weight,
          ),
        ),
        8.horizontalSpace,
        AppText(
          value.isEmpty ? '—' : value,
          color: valueColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: weight,
        ),
      ],
    );
  }
}

/// `"12:30:00"` → `"12:30 pm"`. Empty/malformed input yields an empty string.
String _formatTime(String hhmmss) {
  final value = hhmmss.trim();
  if (value.isEmpty) return '';
  final parts = value.split(':');
  final hours = int.tryParse(parts[0]);
  if (hours == null) return '';
  final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final period = hours >= 12 ? 'pm' : 'am';
  final hours12 = hours % 12 == 0 ? 12 : hours % 12;
  return '$hours12:${minutes.toString().padLeft(2, '0')} $period';
}

/// `"12:30 pm – 11:00 pm"`; empty when neither time is parseable.
String _range(String opening, String closing) {
  final open = _formatTime(opening);
  final close = _formatTime(closing);
  if (open.isEmpty && close.isEmpty) return '';
  if (open.isEmpty) return close;
  if (close.isEmpty) return open;
  return '$open – $close';
}
