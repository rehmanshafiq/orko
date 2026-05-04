import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// EV charging slot booking UI with local selection state.
class BookASlotScreen extends StatefulWidget {
  const BookASlotScreen({super.key});

  @override
  State<BookASlotScreen> createState() => _BookASlotScreenState();
}

class _BookASlotScreenState extends State<BookASlotScreen> {
  static const String _stationTitle = 'HGL Charging Hub Motorway M2';
  static const String _stationAddress = 'Motorway M2, Near Exit 15, XYZ City';

  /// Mock slot grid: base availability only (three visual styles).
  static const List<({String time, _SlotStyle style})> _slotDefs = [
    (time: '08:00', style: _SlotStyle.available),
    (time: '09:00', style: _SlotStyle.booked),
    (time: '10:00', style: _SlotStyle.busy),
    (time: '11:00', style: _SlotStyle.available),
    (time: '12:00', style: _SlotStyle.booked),
    (time: '13:00', style: _SlotStyle.busy),
    (time: '14:00', style: _SlotStyle.available),
    (time: '15:00', style: _SlotStyle.available),
    (time: '16:00', style: _SlotStyle.available),
    (time: '17:00', style: _SlotStyle.booked),
    (time: '18:00', style: _SlotStyle.busy),
  ];

  int _selectedPortIndex = 1;
  /// 0 = Today chip, 1–6 = Mon–Sat pills in the row.
  int _selectedDateSegment = 0;
  String? _selectedTime = '14:00';
  int _durationHours = 1;

  static const int _minDuration = 1;
  static const int _maxDuration = 8;

  static const List<({String day, String date})> _weekPills = [
    (day: 'Mon', date: '21'),
    (day: 'Tue', date: '22'),
    (day: 'Wed', date: '23'),
    (day: 'Thu', date: '24'),
    (day: 'Fri', date: '25'),
    (day: 'Sat', date: '26'),
  ];

  void _onSlotTap(String time, _SlotStyle style) {
    if (style != _SlotStyle.available) return;
    setState(() {
      _selectedTime = _selectedTime == time ? null : time;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUiColors.of(context).scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppUtils.horizontal16Padding,
              child: _buildAppBar(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppUtils.horizontal16Padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    16.verticalSpace,
                    _stationInfoCard(),
                    20.verticalSpace,
                    _sectionTitle('Select Charger Port'),
                    12.verticalSpace,
                    _chargerPortRow(),
                    20.verticalSpace,
                    _sectionTitle('Select Date'),
                    12.verticalSpace,
                    _dateSelectorRow(),
                    20.verticalSpace,
                    _sectionTitle('Available Time Slots'),
                    12.verticalSpace,
                    _timeSlotGrid(),
                    20.verticalSpace,
                    _durationSection(),
                    18.verticalSpace,
                    _bottomSummary(context),
                    16.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.whiteColor, size: 20.sp),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: AppText(
            'Book a Slot',
            textAlign: TextAlign.center,
            color: AppColors.whiteColor,
            fontSize: FontSizes.font18Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
        40.horizontalSpace,
      ],
    );
  }

  Widget _stationInfoCard() {
    return Container(
      width: double.infinity,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            _stationTitle,
            color: AppColors.whiteColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 2,
          ),
          6.verticalSpace,
          AppText(
            _stationAddress,
            color: AppColors.iconsGreyColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          10.verticalSpace,
          Row(
            children: [
              _plugChip('CCS'),
              12.horizontalSpace,
              _plugChip('CHAdeMO'),
              12.horizontalSpace,
              _plugChip('Type 2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _plugChip(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.ev_station_outlined, size: 16.sp, color: AppColors.iconsGreyColor),
        4.horizontalSpace,
        AppText(
          label,
          color: AppColors.iconsGreyColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return AppText(
      title,
      color: AppColors.whiteColor,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight700,
    );
  }

  Widget _chargerPortRow() {
    return SizedBox(
      height: 128.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _portCard(
            portIndex: 0,
            portLabel: 'Port 1',
            specs: 'CCS, 350kW',
          ),
          10.horizontalSpace,
          _portCard(
            portIndex: 1,
            portLabel: 'Port 2',
            specs: 'CCS 150 kW',
          ),
          10.horizontalSpace,
          _portCard(
            portIndex: 2,
            portLabel: 'Port 3',
            specs: 'Type 2, 22kW',
          ),
        ],
      ),
    );
  }

  Widget _portCard({
    required int portIndex,
    required String portLabel,
    required String specs,
  }) {
    final selected = _selectedPortIndex == portIndex;
    final borderColor = selected ? AppColors.primaryDarkColor : AppColors.whiteColor.withValues(alpha: 0.08);
    final glow = selected
        ? [
            BoxShadow(
              color: AppColors.primaryDarkColor.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ]
        : <BoxShadow>[];

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () => setState(() => _selectedPortIndex = portIndex),
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          width: 148.w,
          padding: AppUtils.all12Padding,
          decoration: BoxDecoration(
            color: AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: glow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    portLabel,
                    color: selected ? AppColors.primaryDarkColor : AppColors.whiteColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                  Icon(
                    Icons.electric_bolt_rounded,
                    size: 22.sp,
                    color: selected ? AppColors.primaryDarkColor : AppColors.iconsGreyColor,
                  ),
                ],
              ),
              8.verticalSpace,
              AppText(
                specs,
                color: selected ? AppColors.whiteColor : AppColors.whiteColor.withValues(alpha: 0.85),
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: AppUtils.horizontal8Vertical4Padding,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryDarkColor.withValues(alpha: 0.45)
                        : AppColors.primaryDarkColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: AppText(
                    'Available',
                    color: AppColors.whiteColor.withValues(alpha: selected ? 1.0 : 0.9),
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateSelectorRow() {
    return Container(
      width: double.infinity,
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _todayDateChip(),
          8.horizontalSpace,
          ...List.generate(_weekPills.length, (i) {
            final p = _weekPills[i];
            final segment = i + 1;
            return Expanded(
              child: Center(
                child: _datePill(
                  day: p.day,
                  date: p.date,
                  selected: _selectedDateSegment == segment,
                  onTap: () => setState(() => _selectedDateSegment = segment),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _todayDateChip() {
    final selected = _selectedDateSegment == 0;
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () => setState(() => _selectedDateSegment = 0),
        customBorder: const CircleBorder(),
        child: Container(
          width: 46.w,
          height: 46.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryDarkColor : AppColors.primaryDarkColor.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.whiteColor.withValues(alpha: 0.45) : AppColors.transparentColor,
              width: selected ? 1.5 : 0,
            ),
          ),
          child: AppText(
            'Today',
            color: AppColors.whiteColor,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
      ),
    );
  }

  Widget _datePill({
    required String day,
    required String date,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                day,
                color: selected ? AppColors.primaryDarkColor : AppColors.whiteColor.withValues(alpha: 0.55),
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight500,
              ),
              1.verticalSpace,
              AppText(
                date,
                color: selected ? AppColors.whiteColor : AppColors.whiteColor,
                fontSize: FontSizes.font12Sp,
                fontWeight: selected ? FontWeights.weight700 : FontWeights.weight400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeSlotGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        final spacing = 8.w;
        final itemWidth = ((constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount) - 18.w;
        final itemHeight = 30.h;
        final childAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _slotDefs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 8.h,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final s = _slotDefs[index];
            final isSelected = s.style == _SlotStyle.available && _selectedTime == s.time;
            return _timeChip(
              time: s.time,
              style: s.style,
              width: itemWidth,
              isSelected: isSelected,
              onTap: () => _onSlotTap(s.time, s.style),
            );
          },
        );
      },
    );
  }

  Widget _timeChip({
    required String time,
    required _SlotStyle style,
    required double width,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    late Color bg;
    late Color border;
    late Color textColor;

    switch (style) {
      case _SlotStyle.available:
        bg = AppColors.primaryDarkColor.withValues(alpha: 0.28);
        border = AppColors.primaryDarkColor;
        textColor = AppColors.whiteColor;
        break;
      case _SlotStyle.booked:
        bg = AppColors.slotBookedBackgroundColor;
        border = AppColors.slotBookedBackgroundColor;
        textColor = AppColors.whiteColor;
        break;
      case _SlotStyle.busy:
        bg = AppColors.slotBusyYellowColor;
        border = AppColors.slotBusyYellowColor;
        textColor = AppColors.whiteColor;
        break;
    }

    if (isSelected && style == _SlotStyle.available) {
      bg = AppColors.primaryDarkColor.withValues(alpha: 0.52);
      border = AppColors.whiteColor;
      textColor = AppColors.whiteColor;
    }

    final interactive = style == _SlotStyle.available;

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: interactive ? onTap : null,
        borderRadius: BorderRadius.circular(34.r),
        child: Ink(
          width: width,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(34.r),
            border: Border.all(
              color: border,
              width: style == _SlotStyle.available ? (isSelected ? 2 : 1.5) : 1,
            ),
          ),
          child: Center(
            child: AppText(
              time,
              color: textColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _durationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle('Duration'),
        Row(
          children: [
            _roundIconButton(
              icon: Icons.remove,
              enabled: _durationHours > _minDuration,
              onTap: () {
                if (_durationHours > _minDuration) {
                  setState(() => _durationHours--);
                }
              },
            ),
            10.horizontalSpace,
            AppText(
              _durationHours == 1 ? '1 hour' : '$_durationHours hours',
              color: AppColors.whiteColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
            10.horizontalSpace,
            _roundIconButton(
              icon: Icons.add,
              enabled: _durationHours < _maxDuration,
              onTap: () {
                if (_durationHours < _maxDuration) {
                  setState(() => _durationHours++);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: AppColors.fieldBackgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? AppColors.whiteColor.withValues(alpha: 0.18)
                  : AppColors.whiteColor.withValues(alpha: 0.06),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.whiteColor.withValues(alpha: enabled ? 0.92 : 0.35),
              size: 12.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomSummary(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final buttonW = screenW - 32.w - 24.w;
    final estimated = 450 * _durationHours;
    final kwhNote = 10 * _durationHours;

    return Container(
      width: double.infinity,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Estimated Cost',
            color: AppColors.whiteColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          6.verticalSpace,
          AppText(
            'Rs $estimated for $_durationHours hour${_durationHours == 1 ? '' : 's'} ($kwhNote kWh estimated)',
            color: AppColors.iconsGreyColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          16.verticalSpace,
          PrimaryButtonWidget(
            text: 'Continue to Payment',
            onPress: () => context.push('/payment-method'),
            buttonColor: AppColors.primaryDarkColor,
            fontWeight: FontWeights.weight700,
            fontSize: FontSizes.font15Sp,
            buttonWidth: buttonW,
            cornerRadius: 12.r,
            isEnabled: _selectedTime != null,
          ),
        ],
      ),
    );
  }
}

enum _SlotStyle { available, booked, busy }
