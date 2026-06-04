import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/booking/presentation/models/slot_style.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/slot_chip.dart';

/// Mock slot grid: base availability only (three visual styles).
const List<({String time, SlotStyle style})> kBookingSlotDefinitions = [
  (time: '08:00', style: SlotStyle.available),
  (time: '09:00', style: SlotStyle.booked),
  (time: '10:00', style: SlotStyle.busy),
  (time: '11:00', style: SlotStyle.available),
  (time: '12:00', style: SlotStyle.booked),
  (time: '13:00', style: SlotStyle.busy),
  (time: '14:00', style: SlotStyle.available),
  (time: '15:00', style: SlotStyle.available),
  (time: '16:00', style: SlotStyle.available),
  (time: '17:00', style: SlotStyle.booked),
  (time: '18:00', style: SlotStyle.busy),
];

class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.ui,
    required this.selectedTime,
    required this.onSlotTap,
  });

  final AppUiColors ui;
  final String? selectedTime;
  final void Function(String time, SlotStyle style) onSlotTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        final spacing = 8.w;
        final itemWidth = ((constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount) - 6.w;
        final itemHeight = 30.h;
        final childAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kBookingSlotDefinitions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 8.h,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final s = kBookingSlotDefinitions[index];
            final isSelected = s.style == SlotStyle.available && selectedTime == s.time;
            return SlotChip(
              ui: ui,
              time: s.time,
              style: s.style,
              width: itemWidth,
              isSelected: isSelected,
              onTap: s.style == SlotStyle.available
                  ? () => onSlotTap(s.time, s.style)
                  : null,
            );
          },
        );
      },
    );
  }
}
