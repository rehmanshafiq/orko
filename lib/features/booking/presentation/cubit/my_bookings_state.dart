import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
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
    this.historyStatus = MyBookingsStatus.initial,
    this.historyError,
    this.historySessions = const [],
  });

  final MyBookingsStatus status;
  final String? error;
  final List<MyBookingEntity> bookings;
  final BookingTab selectedTab;

  /// Id of the booking currently being cancelled/rescheduled (per-card spinner).
  final int? actionBookingId;

  /// Lifecycle of the charge-session-history fetch (independent of [status],
  /// since the History tab is driven by a separate endpoint).
  final MyBookingsStatus historyStatus;
  final String? historyError;
  final List<ChargeSessionHistoryEntity> historySessions;

  /// Approved bookings → "Upcoming".
  List<MyBookingEntity> get upcoming =>
      bookings.where((b) => b.isApproved).toList(growable: false);

  bool isActionInProgress(int bookingId) => actionBookingId == bookingId;

  MyBookingsState copyWith({
    MyBookingsStatus? status,
    String? error,
    bool clearError = false,
    List<MyBookingEntity>? bookings,
    BookingTab? selectedTab,
    int? actionBookingId,
    bool clearActionBookingId = false,
    MyBookingsStatus? historyStatus,
    String? historyError,
    bool clearHistoryError = false,
    List<ChargeSessionHistoryEntity>? historySessions,
  }) {
    return MyBookingsState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      bookings: bookings ?? this.bookings,
      selectedTab: selectedTab ?? this.selectedTab,
      actionBookingId: clearActionBookingId
          ? null
          : (actionBookingId ?? this.actionBookingId),
      historyStatus: historyStatus ?? this.historyStatus,
      historyError:
          clearHistoryError ? null : (historyError ?? this.historyError),
      historySessions: historySessions ?? this.historySessions,
    );
  }

  @override
  List<Object?> get props => [
        status,
        error,
        bookings,
        selectedTab,
        actionBookingId,
        historyStatus,
        historyError,
        historySessions,
      ];
}
