import 'package:equatable/equatable.dart';

class BookingState extends Equatable {
  static const int noDateSelected = -1;

  const BookingState({
    this.selectedPortIndex = 1,
    this.selectedDateSegment = noDateSelected,
    this.selectedTime,
    this.durationHours = 3,
  });

  final int selectedPortIndex;
  final int selectedDateSegment;
  final String? selectedTime;
  final int durationHours;

  bool get isDateSelected => selectedDateSegment >= 0;

  BookingState copyWith({
    int? selectedPortIndex,
    int? selectedDateSegment,
    int? durationHours,
    String? selectedTime,
  }) {
    return BookingState(
      selectedPortIndex: selectedPortIndex ?? this.selectedPortIndex,
      selectedDateSegment: selectedDateSegment ?? this.selectedDateSegment,
      durationHours: durationHours ?? this.durationHours,
      selectedTime: selectedTime ?? this.selectedTime,
    );
  }

  /// Toggle-off when the same available slot is tapped again.
  BookingState withToggledTimeSelection(String time) {
    return BookingState(
      selectedPortIndex: selectedPortIndex,
      selectedDateSegment: selectedDateSegment,
      selectedTime: selectedTime == time ? null : time,
      durationHours: durationHours,
    );
  }

  @override
  List<Object?> get props => [
        selectedPortIndex,
        selectedDateSegment,
        selectedTime,
        durationHours,
      ];
}
