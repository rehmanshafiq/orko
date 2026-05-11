import 'package:equatable/equatable.dart';

class BookingState extends Equatable {
  const BookingState({
    this.selectedPortIndex = 1,
    this.selectedDateSegment = 0,
    this.selectedTime = '14:00',
    this.durationHours = 1,
  });

  final int selectedPortIndex;
  final int selectedDateSegment;
  final String? selectedTime;
  final int durationHours;

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
