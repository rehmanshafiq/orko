import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_state.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/charger_port_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/date_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/duration_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/station_info_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/summary_bottom_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/time_slot_grid.dart';

/// EV charging slot booking UI with local selection state.
class BookSlotMobileView extends StatelessWidget {
  const BookSlotMobileView({super.key});

  static const String _stationTitle = 'HGL Charging Hub Motorway M2';
  static const String _stationAddress = 'Motorway M2, Near Exit 15, XYZ City';

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppUtils.horizontal16Padding,
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: ui.textPrimary, size: 20.sp),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: AppText(
                      'Book a Slot',
                      textAlign: TextAlign.center,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font18Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
                  40.horizontalSpace,
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<BookingCubit, BookingState>(
                builder: (context, state) {
                  final cubit = context.read<BookingCubit>();
                  final screenW = MediaQuery.sizeOf(context).width;
                  final buttonW = screenW - 32.w - 24.w;
                  final estimated = 450 * state.durationHours;
                  final kwhNote = 10 * state.durationHours;

                  return SingleChildScrollView(
                    padding: AppUtils.horizontal16Padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        16.verticalSpace,
                        StationInfoCard(
                          title: _stationTitle,
                          address: _stationAddress,
                          ui: ui,
                        ),
                        20.verticalSpace,
                        AppText(
                          'Select Charger Port',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        ChargerPortSelector(
                          ui: ui,
                          selectedPortIndex: state.selectedPortIndex,
                          onPortSelected: cubit.selectPort,
                        ),
                        20.verticalSpace,
                        AppText(
                          'Select Date',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        DateSelector(
                          ui: ui,
                          selectedDateSegment: state.selectedDateSegment,
                          onSelectDate: cubit.selectDate,
                        ),
                        20.verticalSpace,
                        AppText(
                          'Available Time Slots',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        TimeSlotGrid(
                          ui: ui,
                          selectedTime: state.selectedTime,
                          onSlotTap: cubit.selectTime,
                        ),
                        20.verticalSpace,
                        DurationSelector(
                          ui: ui,
                          durationHours: state.durationHours,
                          minDurationHours: BookingCubit.minDuration,
                          maxDurationHours: BookingCubit.maxDuration,
                          onDecrease: cubit.decreaseDuration,
                          onIncrease: cubit.increaseDuration,
                        ),
                        18.verticalSpace,
                        SummaryBottomCard(
                          ui: ui,
                          durationHours: state.durationHours,
                          estimatedCost: estimated,
                          estimatedKwh: kwhNote,
                          buttonWidth: buttonW,
                          isContinueEnabled: state.selectedTime != null,
                          onContinueToPayment: () => context.push('/payment-method'),
                        ),
                        16.verticalSpace,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
