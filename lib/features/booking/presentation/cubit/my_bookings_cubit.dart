import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  MyBookingsCubit() : super(const MyBookingsState()) {
    _loadMockData();
  }

  void selectTab(BookingTab tab) {
    if (tab == state.selectedTab) return;
    emit(state.copyWith(selectedTab: tab));
  }

  void cancelUpcoming(UpcomingBooking booking) {
    final updated = List<UpcomingBooking>.from(state.upcomingBookings)
      ..remove(booking);
    emit(state.copyWith(upcomingBookings: updated));
  }

  void _loadMockData() {
    emit(
      state.copyWith(
        activeSessions: const [],
        upcomingBookings: const [
          UpcomingBooking(
            stationName: 'HGL Ocean Mall',
            powerLabel: '7 KW - HGL',
            statusLabel: 'Reserved',
            dateTimeLabel: '5/25/2026, 5:30:00 PM',
            durationLabel: '15 mins',
            estimatedCost: 0,
          ),
        ],
        historyBookings: const [
          HistoryBooking(
            stationName: 'HGL PSO BTL',
            dateTimeLabel: '5/22/2026, 9:26:33 PM',
            relativeLabel: '2 days ago',
            energyKwh: 0.46,
            statusLabel: 'Completed',
            amount: 45,
          ),
          HistoryBooking(
            stationName: 'HGL - PSO Alfalah',
            dateTimeLabel: '5/14/2026, 11:15:04 PM',
            relativeLabel: '1 week ago',
            energyKwh: 0.12,
            statusLabel: 'Completed',
            amount: 70,
          ),
        ],
      ),
    );
  }
}
