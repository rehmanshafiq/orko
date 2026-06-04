import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_revamped_theme.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/slot_style.dart';

/// EV charging slot booking UI — layout matches product reference.
class BookSlotMobileView extends StatelessWidget {
  const BookSlotMobileView({super.key});

  static const List<({String day, String date})> _datePills = [
    (day: 'MON', date: '13'),
    (day: 'TUE', date: '14'),
    (day: 'WED', date: '15'),
    (day: 'THU', date: '16'),
    (day: 'FRI', date: '17'),
    (day: 'SAT', date: '18'),
    (day: 'SUN', date: '19'),
  ];

  static const List<({String time, SlotStyle style, String statusLabel})>
      _slotDefinitions = [
    (time: '08:00', style: SlotStyle.booked, statusLabel: 'OCCUPIED'),
    (time: '09:30', style: SlotStyle.available, statusLabel: 'AVAILABLE'),
    (time: '11:00', style: SlotStyle.available, statusLabel: 'AVAILABLE'),
    (time: '12:30', style: SlotStyle.available, statusLabel: 'AVAILABLE'),
    (time: '14:00', style: SlotStyle.busy, statusLabel: 'RESERVED'),
    (time: '15:30', style: SlotStyle.available, statusLabel: 'AVAILABLE'),
  ];

  static int _durationMinutes(int durationHours) => durationHours * 15;

  static void _setDurationHours(BookingCubit cubit, int target) {
    final clamped = target.clamp(BookingCubit.minDuration, BookingCubit.maxDuration);
    while (cubit.state.durationHours < clamped) {
      cubit.increaseDuration();
    }
    while (cubit.state.durationHours > clamped) {
      cubit.decreaseDuration();
    }
  }

  static bool _canContinueToPayment(BookingState state) {
    if (!state.isDateSelected || state.selectedTime == null) return false;
    return _slotDefinitions.any(
      (slot) =>
          slot.time == state.selectedTime &&
          slot.style == SlotStyle.available,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.revampedTheme.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            final cubit = context.read<BookingCubit>();
            final durationMinutes = _durationMinutes(state.durationHours);
            final chargingFee = 12.50 * (durationMinutes / 45);
            const stationAccess = 2.00;
            final total = chargingFee + stationAccess;

            return Column(
              children: [
                _BookSlotHeader(onSearch: () => context.push('/search')),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        20.verticalSpace,
                        _ScheduleSection(
                          selectedDateSegment: state.selectedDateSegment,
                          onSelectDate: cubit.selectDate,
                        ),
                        28.verticalSpace,
                        _AvailableSlotsSection(
                          selectedTime: state.selectedTime,
                          onSlotTap: cubit.selectTime,
                        ),
                        28.verticalSpace,
                        _DurationSection(
                          durationMinutes: durationMinutes,
                          durationHours: state.durationHours,
                          onDurationChanged: (hours) =>
                              _setDurationHours(cubit, hours),
                        ),
                        24.verticalSpace,
                        _EstimatedCostCard(
                          durationMinutes: durationMinutes,
                          chargingFee: chargingFee,
                          stationAccess: stationAccess,
                          total: total,
                        ),
                        20.verticalSpace,
                        _ContinueButton(
                          enabled: _canContinueToPayment(state),
                          onPressed: () => context.push('/payment-method'),
                        ),
                        24.verticalSpace,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookSlotHeader extends StatelessWidget {
  const _BookSlotHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: context.revampedTheme.avatarBackground,
            child: Icon(
              Icons.person_rounded,
              color: context.revampedTheme.textMuted,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Center(
              child: AppText(
                'HUBCO',
                color: context.revampedTheme.bookSlotDarkGreen,
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
              color: context.revampedTheme.textPrimary,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.selectedDateSegment,
    required this.onSelectDate,
  });

  final int selectedDateSegment;
  final ValueChanged<int> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'SCHEDULE',
          color: context.revampedTheme.textMuted,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight700,
          letterSpacing: 1.4,
        ),
        6.verticalSpace,
        Row(
          children: [
            Expanded(
              child: AppText(
                'Select Date',
                color: context.revampedTheme.textPrimary,
                fontSize: FontSizes.font26Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
            AppText(
              'May 2024',
              color: context.revampedTheme.textMuted,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
            ),
          ],
        ),
        16.verticalSpace,
        SizedBox(
          height: 90.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: BookSlotMobileView._datePills.length,
            separatorBuilder: (_, __) => 10.horizontalSpace,
            itemBuilder: (context, index) {
              final pill = BookSlotMobileView._datePills[index];
              final selected = selectedDateSegment == index;
              return _DatePill(
                day: pill.day,
                date: pill.date,
                selected: selected,
                onTap: () => onSelectDate(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.day,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final String day;
  final String date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: selected ? t.bookSlotDarkGreen : t.cardBackground,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: t.datePillSelectedShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: t.datePillUnselectedShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                day,
                color: selected ? t.textOnBrand : t.textMuted,
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight600,
                letterSpacing: 0.5,
              ),
              4.verticalSpace,
              AppText(
                date,
                color: selected ? t.textOnBrand : t.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailableSlotsSection extends StatelessWidget {
  const _AvailableSlotsSection({
    required this.selectedTime,
    required this.onSlotTap,
  });

  final String? selectedTime;
  final void Function(String time, SlotStyle style) onSlotTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                'Available Slots',
                color: context.revampedTheme.textPrimary,
                fontSize: FontSizes.font18Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
            _LegendDot(color: context.revampedTheme.bookSlotPrimaryGreen, label: 'AVAIL'),
            10.horizontalSpace,
            _LegendDot(color: context.revampedTheme.takenPink, label: 'TAKEN'),
            10.horizontalSpace,
            _LegendDot(color: context.revampedTheme.heldGreen, label: 'HELD'),
          ],
        ),
        16.verticalSpace,
        LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 3;
            final spacing = 10.w;
            final itemWidth = (constraints.maxWidth -
                    spacing * (crossAxisCount - 1)) /
                crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: 10.h,
              children: BookSlotMobileView._slotDefinitions.map((slot) {
                final isSelected = slot.style == SlotStyle.available &&
                    selectedTime == slot.time;
                return SizedBox(
                  width: itemWidth,
                  child: _TimeSlotCard(
                    time: slot.time,
                    style: slot.style,
                    statusLabel: isSelected ? 'SELECTED' : slot.statusLabel,
                    isSelected: isSelected,
                    onTap: slot.style == SlotStyle.available
                        ? () => onSlotTap(slot.time, slot.style)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        4.horizontalSpace,
        AppText(
          label,
          color: context.revampedTheme.textMuted,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight600,
          letterSpacing: 0.3,
        ),
      ],
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  const _TimeSlotCard({
    required this.time,
    required this.style,
    required this.statusLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String time;
  final SlotStyle style;
  final String statusLabel;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    late Color background;
    late Color border;
    late Color timeColor;
    late Color statusColor;

    if (isSelected) {
      background = t.bookSlotPrimaryGreen;
      border = t.bookSlotDarkGreen;
      timeColor = t.textPrimary;
      statusColor = t.textPrimary;
    } else {
      switch (style) {
        case SlotStyle.available:
          background = t.cardBackground;
          border = t.availableSlotBorder;
          timeColor = t.textPrimary;
          statusColor = t.bookSlotPrimaryGreen;
        case SlotStyle.booked:
          background = t.cardBackground;
          border = t.progressTrack;
          timeColor = t.textMuted;
          statusColor = t.textMuted;
        case SlotStyle.busy:
          background = t.heldGreen.withValues(alpha: 0.5);
          border = t.heldGreen;
          timeColor = t.textMuted;
          statusColor = t.textMuted;
      }
    }

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              AppText(
                time,
                color: timeColor,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
              ),
              4.verticalSpace,
              AppText(
                statusLabel,
                color: statusColor,
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight600,
                letterSpacing: 0.4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationSection extends StatelessWidget {
  const _DurationSection({
    required this.durationMinutes,
    required this.durationHours,
    required this.onDurationChanged,
  });

  final int durationMinutes;
  final int durationHours;
  final ValueChanged<int> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final showOptimal = durationMinutes == 45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Duration',
          color: context.revampedTheme.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        14.verticalSpace,
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          decoration: BoxDecoration(
            color: t.durationCardBackground,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppFonts.lexend,
                        color: context.revampedTheme.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '$durationMinutes',
                          style: TextStyle(
                            fontSize: FontSizes.font32Sp,
                            fontWeight: FontWeights.weight700,
                          ),
                        ),
                        TextSpan(
                          text: ' min',
                          style: TextStyle(
                            fontSize: FontSizes.font18Sp,
                            fontWeight: FontWeights.weight500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showOptimal) ...[
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.revampedTheme.bookSlotPrimaryGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: AppText(
                        'OPTIMAL CHARGE',
                        color: context.revampedTheme.textPrimary,
                        fontSize: FontSizes.font10Sp,
                        fontWeight: FontWeights.weight700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
              20.verticalSpace,
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.h,
                  activeTrackColor: context.revampedTheme.bookSlotPrimaryGreen,
                  inactiveTrackColor: t.cardBackground,
                  thumbColor: AppColors.whiteColor,
                  overlayColor: AppColors.transparentColor,
                  showValueIndicator: ShowValueIndicator.never,
                  thumbShape: _GreenBorderThumbShape(radius: 12.r),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                ),
                child: Slider(
                  value: durationHours.toDouble(),
                  min: BookingCubit.minDuration.toDouble(),
                  max: BookingCubit.maxDuration.toDouble(),
                  divisions: BookingCubit.maxDuration - BookingCubit.minDuration,
                  onChanged: (value) => onDurationChanged(value.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    '15 MIN',
                    color: context.revampedTheme.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                    letterSpacing: 0.5,
                  ),
                  AppText(
                    '120 MIN',
                    color: context.revampedTheme.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                    letterSpacing: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// White slider thumb with a black ring.
class _GreenBorderThumbShape extends SliderComponentShape {
  const _GreenBorderThumbShape({required this.radius});

  final double radius;

  static const double _borderWidth = 3;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius + _borderWidth);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.whiteColor,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.blackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );
  }
}

class _EstimatedCostCard extends StatelessWidget {
  const _EstimatedCostCard({
    required this.durationMinutes,
    required this.chargingFee,
    required this.stationAccess,
    required this.total,
  });

  final int durationMinutes;
  final double chargingFee;
  final double stationAccess;
  final double total;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'ESTIMATED COST',
            color: context.revampedTheme.textPrimary,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight700,
            letterSpacing: 1.2,
          ),
          16.verticalSpace,
          _CostRow(
            label: 'Charging Fee ($durationMinutes min)',
            value: 'PKR ${chargingFee.toStringAsFixed(2)}',
          ),
          10.verticalSpace,
          _CostRow(
            label: 'Station Access',
            value: 'PKR ${stationAccess.toStringAsFixed(2)}',
          ),
          16.verticalSpace,
          Divider(color: t.progressTrack, height: 1),
          14.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Total',
                color: context.revampedTheme.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
              AppText(
                'PKR ${total.toStringAsFixed(2)}',
                color: context.revampedTheme.bookSlotDarkGreen,
                fontSize: FontSizes.font24Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          color: context.revampedTheme.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight400,
        ),
        AppText(
          value,
          color: context.revampedTheme.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [
                    t.bookSlotDarkGreen,
                    t.bookSlotPrimaryGreen,
                  ]
                : [
                    t.disabledButtonGrey,
                    t.disabledButtonGrey,
                  ],
          ),
          borderRadius: BorderRadius.circular(34.r),
        ),
        child: Material(
          color: AppColors.transparentColor,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(34.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    'Continue to Payment',
                    color: t.textOnBrand,
                    fontSize: FontSizes.font16Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                  8.horizontalSpace,
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: enabled ? t.textOnBrand : t.textMuted,
                    size: 20.sp,
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
