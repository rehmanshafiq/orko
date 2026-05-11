import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/slot_style.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(const BookingState());

  static const int minDuration = 1;
  static const int maxDuration = 8;

  void selectPort(int index) {
    emit(state.copyWith(selectedPortIndex: index));
  }

  void selectDate(int index) {
    emit(state.copyWith(selectedDateSegment: index));
  }

  void selectTime(String time, SlotStyle style) {
    if (style != SlotStyle.available) return;
    emit(state.withToggledTimeSelection(time));
  }

  void increaseDuration() {
    if (state.durationHours >= maxDuration) return;
    emit(state.copyWith(durationHours: state.durationHours + 1));
  }

  void decreaseDuration() {
    if (state.durationHours <= minDuration) return;
    emit(state.copyWith(durationHours: state.durationHours - 1));
  }
}
