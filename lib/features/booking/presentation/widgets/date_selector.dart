import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/date_chip.dart';

/// Date strip driven by real dates. Index 0 renders as the circular "Today"
/// chip; the remaining entries render as day/date pills.
class DateSelector extends StatelessWidget {
  const DateSelector({
    super.key,
    required this.ui,
    required this.dateOptions,
    required this.selectedIndex,
    required this.onSelectDate,
  });

  final AppUiColors ui;
  final List<DateTime> dateOptions;
  final int selectedIndex;
  final ValueChanged<int> onSelectDate;

  static final DateFormat _day = DateFormat('EEE');
  static final DateFormat _date = DateFormat('d');

  @override
  Widget build(BuildContext context) {
    if (dateOptions.isEmpty) return const SizedBox.shrink();

    final pills = <Widget>[];
    for (var i = 1; i < dateOptions.length; i++) {
      final d = dateOptions[i];
      pills.add(
        DateChip(
          ui: ui,
          day: _day.format(d),
          date: _date.format(d),
          selected: selectedIndex == i,
          onTap: () => onSelectDate(i),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ui.cardBookingBackground,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TodayDateChip(
            ui: ui,
            selected: selectedIndex == 0,
            onTap: () => onSelectDate(0),
          ),
          12.horizontalSpace,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: pills,
            ),
          ),
        ],
      ),
    );
  }
}
