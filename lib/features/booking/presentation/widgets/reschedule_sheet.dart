import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_booking_slots_usecase.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/date_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/time_slot_grid.dart';

/// New date/slot chosen in the reschedule sheet.
class RescheduleResult {
  const RescheduleResult({
    required this.date,
    required this.startTime,
  });

  /// `YYYY-MM-DD`.
  final String date;

  /// `HH:mm`. end_time is auto-derived by the backend, so it isn't carried.
  final String startTime;
}

/// Bottom sheet that lets the user pick a new date + available slot for a
/// booking. Pops with a [RescheduleResult] on confirm, or null on dismiss.
class RescheduleSheet extends StatefulWidget {
  const RescheduleSheet({super.key, required this.booking});

  final MyBookingEntity booking;

  static Future<RescheduleResult?> show(
    BuildContext context,
    MyBookingEntity booking,
  ) {
    return showModalBottomSheet<RescheduleResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppUiColors.of(context).scaffoldBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => RescheduleSheet(booking: booking),
    );
  }

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  static const int _dateOptionCount = 7;
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  final GetBookingSlotsUseCase _getSlots = sl<GetBookingSlotsUseCase>();

  late final List<DateTime> _dateOptions;
  int _selectedDateIndex = 0;

  _Status _status = _Status.loading;
  String? _error;
  List<BookingSlotEntity> _slots = const [];
  BookingSlotEntity? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dateOptions = List<DateTime>.generate(
      _dateOptionCount,
      (i) => today.add(Duration(days: i)),
    );
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _status = _Status.loading;
      _error = null;
      _selectedSlot = null;
    });

    final result = await _getSlots(
      GetBookingSlotsParams(
        date: _apiDate.format(_dateOptions[_selectedDateIndex]),
        locationId: widget.booking.locationId,
      ),
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _status = _Status.failure;
        _error = failure.message;
        _slots = const [];
      }),
      (slots) => setState(() {
        _status = _Status.success;
        _slots = slots.where((s) => s.isAvailable).toList(growable: false);
      }),
    );
  }

  void _selectDate(int index) {
    if (index == _selectedDateIndex) return;
    setState(() => _selectedDateIndex = index);
    _loadSlots();
  }

  void _selectSlot(BookingSlotEntity slot) {
    setState(() {
      _selectedSlot =
          _selectedSlot?.startTime == slot.startTime ? null : slot;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: ui.borderSubtle,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                14.verticalSpace,
                AppText(
                  'Reschedule Booking',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font18Sp,
                  fontWeight: FontWeights.weight700,
                ),
                4.verticalSpace,
                AppText(
                  widget.booking.displayName,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font13Sp,
                  fontWeight: FontWeights.weight400,
                ),
                16.verticalSpace,
                AppText(
                  'Select Date',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
                10.verticalSpace,
                DateSelector(
                  ui: ui,
                  dateOptions: _dateOptions,
                  selectedIndex: _selectedDateIndex,
                  onSelectDate: _selectDate,
                ),
                16.verticalSpace,
                AppText(
                  'Available Time Slots',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
                12.verticalSpace,
                Flexible(child: SingleChildScrollView(child: _buildSlots(ui))),
                16.verticalSpace,
                PrimaryButtonWidget(
                  text: 'Confirm Reschedule',
                  onPress: _selectedSlot == null
                      ? null
                      : () => Navigator.of(context).pop(
                            RescheduleResult(
                              date: _apiDate
                                  .format(_dateOptions[_selectedDateIndex]),
                              startTime: _selectedSlot!.startTime,
                            ),
                          ),
                  isEnabled: _selectedSlot != null,
                  buttonHeight: 44.h,
                  cornerRadius: 24.r,
                  gradientColors: const [
                    AppColors.primaryDarkColor,
                    AppColors.primaryDarkButtonColor,
                  ],
                  fontSize: FontSizes.font15Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlots(AppUiColors ui) {
    switch (_status) {
      case _Status.loading:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: SizedBox(
              width: 26.w,
              height: 26.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: ui.brandPrimary,
              ),
            ),
          ),
        );
      case _Status.failure:
        return _message(ui, _error ?? 'Could not load time slots.');
      case _Status.success:
        if (_slots.isEmpty) {
          return _message(ui, 'No available slots for this date.');
        }
        return TimeSlotGrid(
          ui: ui,
          slots: _slots,
          selectedStartTime: _selectedSlot?.startTime,
          onSlotTap: _selectSlot,
        );
    }
  }

  Widget _message(AppUiColors ui, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          AppText(
            message,
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight500,
          ),
          10.verticalSpace,
          TextButton(
            onPressed: _loadSlots,
            child: AppText(
              'Retry',
              color: ui.brandPrimary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Status { loading, failure, success }
