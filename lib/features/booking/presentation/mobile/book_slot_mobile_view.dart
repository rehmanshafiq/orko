import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/slot_style.dart';

/// EV charging slot booking UI — layout matches product reference.
class BookSlotMobileView extends StatelessWidget {
  const BookSlotMobileView({super.key});

  static const Color _bgColor = Color(0xFFF8F9FB);
  static const Color _primaryGreen = Color(0xFF00C48C);
  static const Color _darkGreen = Color(0xFF004D40);
  static const Color _scheduleLabelGreen = Color(0xFF6EE7B7);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _takenPink = Color(0xFFF9A8D4);
  static const Color _heldGreen = Color(0xFFD1FAE5);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
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
                          enabled: state.selectedTime != null,
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
            backgroundColor: AppColors.shimmerGreyColor,
            child: Icon(
              Icons.person_rounded,
              color: BookSlotMobileView._textMuted,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Center(
              child: AppText(
                'HUBCO',
                color: BookSlotMobileView._darkGreen,
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
              color: BookSlotMobileView._textDark,
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
          color: BookSlotMobileView._scheduleLabelGreen,
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
                color: BookSlotMobileView._textDark,
                fontSize: FontSizes.font26Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
            AppText(
              'May 2024',
              color: BookSlotMobileView._textMuted,
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
            color: selected ? BookSlotMobileView._darkGreen : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: BookSlotMobileView._darkGreen.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.blackColor.withValues(alpha: 0.04),
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
                color: selected ? AppColors.whiteColor : BookSlotMobileView._textMuted,
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight600,
                letterSpacing: 0.5,
              ),
              4.verticalSpace,
              AppText(
                date,
                color: selected ? AppColors.whiteColor : BookSlotMobileView._textDark,
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
                color: BookSlotMobileView._textDark,
                fontSize: FontSizes.font18Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
            _LegendDot(color: BookSlotMobileView._primaryGreen, label: 'AVAIL'),
            10.horizontalSpace,
            _LegendDot(color: BookSlotMobileView._takenPink, label: 'TAKEN'),
            10.horizontalSpace,
            _LegendDot(color: BookSlotMobileView._heldGreen, label: 'HELD'),
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
          color: BookSlotMobileView._textMuted,
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
    late Color background;
    late Color border;
    late Color timeColor;
    late Color statusColor;

    if (isSelected) {
      background = BookSlotMobileView._primaryGreen;
      border = BookSlotMobileView._darkGreen;
      timeColor = BookSlotMobileView._textDark;
      statusColor = BookSlotMobileView._textDark;
    } else {
      switch (style) {
        case SlotStyle.available:
          background = AppColors.whiteColor;
          border = BookSlotMobileView._primaryGreen.withValues(alpha: 0.45);
          timeColor = BookSlotMobileView._textDark;
          statusColor = BookSlotMobileView._primaryGreen;
        case SlotStyle.booked:
          background = AppColors.whiteColor;
          border = AppColors.shimmerGreyColor;
          timeColor = BookSlotMobileView._textMuted;
          statusColor = BookSlotMobileView._textMuted;
        case SlotStyle.busy:
          background = BookSlotMobileView._heldGreen.withValues(alpha: 0.5);
          border = BookSlotMobileView._heldGreen;
          timeColor = BookSlotMobileView._textMuted;
          statusColor = BookSlotMobileView._textMuted;
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
    final showOptimal = durationMinutes == 45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Duration',
          color: BookSlotMobileView._textDark,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        14.verticalSpace,
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          decoration: BoxDecoration(
            color: AppColors.shimmerGreyColor.withValues(alpha: 0.55),
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
                        color: BookSlotMobileView._textDark,
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
                    12.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: BookSlotMobileView._primaryGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: AppText(
                        'OPTIMAL CHARGE',
                        color: BookSlotMobileView._darkGreen,
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
                  activeTrackColor: BookSlotMobileView._primaryGreen,
                  inactiveTrackColor: AppColors.whiteColor,
                  thumbColor: AppColors.whiteColor,
                  overlayColor:
                      BookSlotMobileView._primaryGreen.withValues(alpha: 0.12),
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
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
                    color: BookSlotMobileView._textMuted,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                    letterSpacing: 0.5,
                  ),
                  AppText(
                    '120 MIN',
                    color: BookSlotMobileView._textMuted,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.05),
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
            color: BookSlotMobileView._textMuted,
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
          Divider(color: AppColors.shimmerGreyColor, height: 1),
          14.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Total',
                color: BookSlotMobileView._textDark,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
              AppText(
                'PKR ${total.toStringAsFixed(2)}',
                color: BookSlotMobileView._darkGreen,
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
          color: BookSlotMobileView._textMuted,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight400,
        ),
        AppText(
          value,
          color: BookSlotMobileView._textDark,
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
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [
                    BookSlotMobileView._darkGreen,
                    BookSlotMobileView._primaryGreen,
                  ]
                : [
                    AppColors.thumbBarGreyColor,
                    AppColors.thumbBarGreyColor,
                  ],
          ),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Material(
          color: AppColors.transparentColor,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(14.r),
            child: Center(
              child: AppText(
                'Continue to Payment',
                color: AppColors.whiteColor,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
