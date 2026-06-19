import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

/// Lifecycle of the my-bookings fetch.
enum MyBookingsStatus { initial, loading, success, failure }

class MyBookingsState extends Equatable {
  const MyBookingsState({
    this.status = MyBookingsStatus.initial,
    this.error,
    this.bookings = const [],
    this.selectedTab = BookingTab.upcoming,
    this.actionBookingId,
  });

  final MyBookingsStatus status;
  final String? error;
  final List<MyBookingEntity> bookings;
  final BookingTab selectedTab;

  /// Id of the booking currently being cancelled/rescheduled (per-card spinner).
  final int? actionBookingId;

  /// Approved bookings → "Upcoming".
  List<MyBookingEntity> get upcoming =>
      bookings.where((b) => b.isApproved).toList(growable: false);

  /// Cancelled bookings → "History".
  List<MyBookingEntity> get history =>
      bookings.where((b) => b.isCancelled).toList(growable: false);

  bool isActionInProgress(int bookingId) => actionBookingId == bookingId;

  MyBookingsState copyWith({
    MyBookingsStatus? status,
    String? error,
    bool clearError = false,
    List<MyBookingEntity>? bookings,
    BookingTab? selectedTab,
    int? actionBookingId,
    bool clearActionBookingId = false,
  }) {
    return MyBookingsState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      bookings: bookings ?? this.bookings,
      selectedTab: selectedTab ?? this.selectedTab,
      actionBookingId:
          clearActionBookingId ? null : (actionBookingId ?? this.actionBookingId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        error,
        bookings,
        selectedTab,
        actionBookingId,
      ];
}
