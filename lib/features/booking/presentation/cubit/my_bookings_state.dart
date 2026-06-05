import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

class MyBookingsState extends Equatable {
  const MyBookingsState({
    this.selectedTab = BookingTab.active,
    this.activeSessions = const [],
    this.upcomingBookings = const [],
    this.historyBookings = const [],
  });

  final BookingTab selectedTab;
  final List<ActiveSession> activeSessions;
  final List<UpcomingBooking> upcomingBookings;
  final List<HistoryBooking> historyBookings;

  MyBookingsState copyWith({
    BookingTab? selectedTab,
    List<ActiveSession>? activeSessions,
    List<UpcomingBooking>? upcomingBookings,
    List<HistoryBooking>? historyBookings,
  }) {
    return MyBookingsState(
      selectedTab: selectedTab ?? this.selectedTab,
      activeSessions: activeSessions ?? this.activeSessions,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      historyBookings: historyBookings ?? this.historyBookings,
    );
  }

  @override
  List<Object?> get props => [
        selectedTab,
        activeSessions,
        upcomingBookings,
        historyBookings,
      ];
}
