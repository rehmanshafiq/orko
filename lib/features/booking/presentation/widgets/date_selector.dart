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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        children: [
          TodayDateChip(
            ui: ui,
            selected: selectedDateSegment == 0,
            onTap: () => onSelectDate(0),
          ),
          10.horizontalSpace,
          Container(width: 1, height: 36.h, color: ui.dividerLine),
          8.horizontalSpace,
          ...List.generate(_weekPills.length, (i) {
            final p = _weekPills[i];
            final segment = i + 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: DateChip(
                  ui: ui,
                  day: p.day,
                  date: p.date,
                  selected: selectedDateSegment == segment,
                  onTap: () => onSelectDate(segment),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
