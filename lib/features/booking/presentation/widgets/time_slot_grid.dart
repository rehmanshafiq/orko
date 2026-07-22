import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/presentation/models/slot_style.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/slot_chip.dart';

/// Renders the slots returned by the API. Unavailable slots are greyed out
/// (non-interactive); selected slots are highlighted. Supports multi-select
/// via [selectedStartTimes] (e.g. two consecutive slots for a 1-hour booking).
///
/// When [isOutOfHours] returns true for a slot, it is shown greyed out and
/// cannot be selected (outside station operating hours).
class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.ui,
    required this.slots,
    required this.selectedStartTimes,
    required this.onSlotTap,
    this.isOutOfHours,
  });

  final AppUiColors ui;
  final List<BookingSlotEntity> slots;
  final Set<String> selectedStartTimes;
  final void Function(BookingSlotEntity slot) onSlotTap;

  /// Optional predicate — when true, the slot is disabled (out of service hours).
  final bool Function(BookingSlotEntity slot)? isOutOfHours;

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
            final outOfHours = isOutOfHours?.call(slot) ?? false;
            final canSelect = slot.isAvailable && !outOfHours;
            final isSelected =
                canSelect && selectedStartTimes.contains(slot.startTime);

            late final SlotStyle style;
            if (outOfHours) {
              style = SlotStyle.outOfHours;
            } else if (slot.isAvailable) {
              style = SlotStyle.available;
            } else {
              style = SlotStyle.booked;
            }

            return SlotChip(
              ui: ui,
              time: slot.startTime,
              style: style,
              width: itemWidth,
              isSelected: isSelected,
              onTap: canSelect ? () => onSlotTap(slot) : null,
            );
          },
        );
      },
    );
  }
}
