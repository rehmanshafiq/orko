import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/presentation/models/slot_style.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/slot_chip.dart';

/// Renders the slots returned by the API. Unavailable slots are greyed out
/// (non-interactive); selected slots are highlighted. Supports multi-select
/// via [selectedStartTimes] (e.g. two consecutive slots for a 1-hour booking).
class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.ui,
    required this.slots,
    required this.selectedStartTimes,
    required this.onSlotTap,
  });

  final AppUiColors ui;
  final List<BookingSlotEntity> slots;
  final Set<String> selectedStartTimes;
  final void Function(BookingSlotEntity slot) onSlotTap;

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
          itemCount: slots.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 8.h,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final slot = slots[index];
            final isSelected = slot.isAvailable &&
                selectedStartTimes.contains(slot.startTime);
            return SlotChip(
              ui: ui,
              time: slot.startTime,
              style: slot.isAvailable ? SlotStyle.available : SlotStyle.booked,
              width: itemWidth,
              isSelected: isSelected,
              onTap: () => onSlotTap(slot),
            );
          },
        );
      },
    );
  }
}
