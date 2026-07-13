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

/// New date/slot(s) chosen in the reschedule sheet.
class RescheduleResult {
  const RescheduleResult({
    required this.date,
    required this.startTime,
    this.noOfSlots = 1,
  });

  /// `YYYY-MM-DD`.
  final String date;

  /// `HH:mm` — start of the first slot. end_time is auto-derived by the
  /// backend (start + 30 × [noOfSlots] min), so it isn't carried.
  final String startTime;

  /// Number of consecutive 30-min slots (1 or 2).
  final int noOfSlots;
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

  /// The API books 30-min slots and supports at most 2 consecutive slots
  /// (a 1-hour booking).
  static const int _maxSlotsPerBooking = 2;

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  final GetBookingSlotsUseCase _getSlots = sl<GetBookingSlotsUseCase>();

  late final List<DateTime> _dateOptions;
  int _selectedDateIndex = 0;

  _Status _status = _Status.loading;
  String? _error;
  List<BookingSlotEntity> _slots = const [];

  /// Selected slots, kept sorted by start time (up to 2 consecutive).
  List<BookingSlotEntity> _selectedSlots = const [];

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
      _selectedSlots = const [];
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

  /// Same consecutive-slot selection rules as the booking screen: tap toggles
  /// a slot off; an adjacent tap extends the block up to [_maxSlotsPerBooking];
  /// any other tap restarts the selection from the tapped slot.
  void _selectSlot(BookingSlotEntity slot) {
    final current = List<BookingSlotEntity>.from(_selectedSlots);
    final alreadyIndex =
        current.indexWhere((s) => s.startTime == slot.startTime);

    List<BookingSlotEntity> next;
    if (alreadyIndex >= 0) {
      current.removeAt(alreadyIndex);
      next = current;
    } else if (current.isEmpty) {
      next = [slot];
    } else if (current.length < _maxSlotsPerBooking &&
        _isAdjacentToSelection(current, slot)) {
      next = [...current, slot]
        ..sort(
            (a, b) => _minutes(a.startTime).compareTo(_minutes(b.startTime)));
    } else {
      next = [slot];
    }

    setState(() => _selectedSlots = next);
  }

  /// True when [slot] directly precedes or follows the selected block.
  bool _isAdjacentToSelection(
    List<BookingSlotEntity> selection,
    BookingSlotEntity slot,
  ) {
    final slotStart = _minutes(slot.startTime);
    final slotEnd = _minutes(slot.endTime);
    if (slotStart < 0 || slotEnd < 0) return false;
    return slotStart == _minutes(selection.last.endTime) ||
        slotEnd == _minutes(selection.first.startTime);
  }

  /// Parses `HH:mm` to minutes-since-midnight; -1 when unparseable.
  static int _minutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return -1;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return -1;
    return h * 60 + m;
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
                4.verticalSpace,
                AppText(
                  'Each slot is 30 min — select 2 consecutive slots for a '
                  '1-hour booking.',
                  color: ui.textSecondary,
                  fontSize: FontSizes.font11Sp,
                  fontWeight: FontWeights.weight400,
                ),
                12.verticalSpace,
                Flexible(child: SingleChildScrollView(child: _buildSlots(ui))),
                16.verticalSpace,
                PrimaryButtonWidget(
                  text: 'Confirm Reschedule',
                  onPress: _selectedSlots.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                            RescheduleResult(
                              date: _apiDate
                                  .format(_dateOptions[_selectedDateIndex]),
                              startTime: _selectedSlots.first.startTime,
                              noOfSlots: _selectedSlots.length,
                            ),
                          ),
                  isEnabled: _selectedSlots.isNotEmpty,
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
          selectedStartTimes: {
            for (final s in _selectedSlots) s.startTime,
          },
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
