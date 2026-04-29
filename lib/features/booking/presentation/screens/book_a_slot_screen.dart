import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// EV charging slot booking UI (static presentation; selections match design mock).
class BookASlotScreen extends StatelessWidget {
  const BookASlotScreen({super.key});

  static const String _stationTitle = 'HGL Charging Hub Motorway M2';
  static const String _stationAddress = 'Motorway M2, Near Exit 15, XYZ City';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
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
                    _sectionTitle('Duration'),
                    12.verticalSpace,
                    _durationRow(),
                    24.verticalSpace,
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
            fontSize: FontSizes.font16Sp,
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
      fontSize: FontSizes.font16Sp,
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
            portLabel: 'Port 1',
            specs: 'CCS, 350kW',
            selected: false,
          ),
          10.horizontalSpace,
          _portCard(
            portLabel: 'Port 2',
            specs: 'CCS 150 kW',
            selected: true,
          ),
          10.horizontalSpace,
          _portCard(
            portLabel: 'Port 3',
            specs: 'Type 2, 22kW',
            selected: false,
          ),
        ],
      ),
    );
  }

  Widget _portCard({
    required String portLabel,
    required String specs,
    required bool selected,
  }) {
    final borderColor = selected ? AppColors.primaryLightColor : AppColors.whiteColor.withValues(alpha: 0.08);
    final glow = selected
        ? [
            BoxShadow(
              color: AppColors.primaryLightColor.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ]
        : <BoxShadow>[];

    return Container(
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
                color: selected ? AppColors.primaryLightColor : AppColors.whiteColor,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
              Icon(
                Icons.electric_bolt_rounded,
                size: 22.sp,
                color: selected ? AppColors.primaryLightColor : AppColors.iconsGreyColor,
              ),
            ],
          ),
          8.verticalSpace,
          AppText(
            specs,
            color: selected ? AppColors.primaryLightColor : AppColors.whiteColor.withValues(alpha: 0.85),
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
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
                color: selected ? AppColors.primaryLightColor : AppColors.primaryLightColor.withValues(alpha: 0.9),
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateSelectorRow() {
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _todayDateChip(),
            14.horizontalSpace,
            _datePill('Mon', '21'),
            14.horizontalSpace,
            _datePill('Tue', '22'),
            14.horizontalSpace,
            _datePill('Wed', '23'),
            14.horizontalSpace,
            _datePill('Thu', '24'),
            14.horizontalSpace,
            _datePill('Fri', '25'),
          ],
        ),
      ),
    );
  }

  Widget _todayDateChip() {
    return Container(
      width: 64.w,
      height: 64.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryLightColor,
        shape: BoxShape.circle,
      ),
      child: AppText(
        'Today',
        color: AppColors.blackColor,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight700,
      ),
    );
  }

  Widget _datePill(String day, String date) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          day,
          color: AppColors.iconsGreyColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight500,
        ),
        4.verticalSpace,
        AppText(
          date,
          color: AppColors.whiteColor,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }

  Widget _timeSlotGrid() {
    final slots = <({String time, _SlotStyle style})>[
      (time: '08:00', style: _SlotStyle.available),
      (time: '09:00', style: _SlotStyle.booked),
      (time: '10:00', style: _SlotStyle.busy),
      (time: '11:00', style: _SlotStyle.available),
      (time: '12:00', style: _SlotStyle.booked),
      (time: '13:00', style: _SlotStyle.busy),
      (time: '14:00', style: _SlotStyle.selected),
      (time: '15:00', style: _SlotStyle.available),
      (time: '16:00', style: _SlotStyle.available),
      (time: '17:00', style: _SlotStyle.booked),
      (time: '10:00', style: _SlotStyle.busy),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = 4;
        final spacing = 8.w;
        final itemWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: 8.h,
          children: slots
              .map(
                (s) => _timeChip(
                  s.time,
                  s.style,
                  width: itemWidth,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _timeChip(String time, _SlotStyle style, {required double width}) {
    late Color bg;
    late Color border;
    late Color textColor;

    switch (style) {
      case _SlotStyle.available:
        bg = AppColors.primaryDarkColor.withValues(alpha: 0.28);
        border = AppColors.primaryLightColor;
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
      case _SlotStyle.selected:
        bg = AppColors.primaryLightColor;
        border = AppColors.primaryLightColor;
        textColor = AppColors.whiteColor;
        break;
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: border, width: style == _SlotStyle.available ? 1.5 : 1),
      ),
      alignment: Alignment.center,
      child: AppText(
        time,
        color: textColor,
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }

  Widget _durationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _roundIconButton(icon: Icons.remove),
        24.horizontalSpace,
        AppText(
          '1 hour',
          color: AppColors.whiteColor,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight600,
        ),
        24.horizontalSpace,
        _roundIconButton(icon: Icons.add),
      ],
    );
  }

  Widget _roundIconButton({required IconData icon}) {
    return Material(
      color: AppColors.fieldBackgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: Padding(
          padding: AppUtils.all12Padding,
          child: Icon(icon, color: AppColors.whiteColor, size: 20.sp),
        ),
      ),
    );
  }

  Widget _bottomSummary(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final buttonW = screenW - 32.w - 24.w;

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
            fontSize: FontSizes.font16Sp,
            fontWeight: FontWeights.weight700,
          ),
          6.verticalSpace,
          AppText(
            'Rs 450 for 1 hour (10 kWh estimated)',
            color: AppColors.iconsGreyColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          16.verticalSpace,
          PrimaryButtonWidget(
            text: 'Continue to Payment',
            onPress: () {},
            buttonColor: AppColors.primaryLightColor,
            fontWeight: FontWeights.weight700,
            fontSize: FontSizes.font15Sp,
            buttonWidth: buttonW,
            cornerRadius: 12.r,
          ),
        ],
      ),
    );
  }
}

enum _SlotStyle { available, booked, busy, selected }
