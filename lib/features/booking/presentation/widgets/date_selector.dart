import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/date_chip.dart';

class DateSelector extends StatelessWidget {
  const DateSelector({
    super.key,
    required this.ui,
    required this.selectedDateSegment,
    required this.onSelectDate,
  });

  final AppUiColors ui;
  final int selectedDateSegment;
  final ValueChanged<int> onSelectDate;

  static const List<({String day, String date})> _weekPills = [
    (day: 'Mon', date: '21'),
    (day: 'Tue', date: '22'),
    (day: 'Wed', date: '23'),
    (day: 'Thu', date: '24'),
    (day: 'Fri', date: '25'),
    (day: 'Sat', date: '26'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TodayDateChip(
            ui: ui,
            selected: selectedDateSegment == 0,
            onTap: () => onSelectDate(0),
          ),
          12.horizontalSpace,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_weekPills.length, (i) {
                final p = _weekPills[i];
                final segment = i + 1;
                return DateChip(
                  ui: ui,
                  day: p.day,
                  date: p.date,
                  selected: selectedDateSegment == segment,
                  onTap: () => onSelectDate(segment),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
