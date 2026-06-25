import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
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
    this.upcomingFilter = UpcomingFilter.approved,
    this.actionBookingId,
    this.historyStatus = MyBookingsStatus.initial,
    this.historyError,
    this.historySessions = const [],
    this.liveStatus = MyBookingsStatus.initial,
    this.liveError,
    this.liveSession,
  });

  final MyBookingsStatus status;
  final String? error;
  final List<MyBookingEntity> bookings;
  final BookingTab selectedTab;

  /// Active sub-tab within the Upcoming tab (Approved / Cancelled).
  final UpcomingFilter upcomingFilter;

  /// Id of the booking currently being cancelled/rescheduled (per-card spinner).
  final int? actionBookingId;

  /// Lifecycle of the charge-session-history fetch (independent of [status],
  /// since the History tab is driven by a separate endpoint).
  final MyBookingsStatus historyStatus;
  final String? historyError;
  final List<ChargeSessionHistoryEntity> historySessions;

  /// Lifecycle of the live-session fetch (Active tab), independent of [status].
  final MyBookingsStatus liveStatus;
  final String? liveError;
  final LiveSessionEntity? liveSession;

  /// Upcoming → Approved sub-tab (`booking_status: approved`).
  List<MyBookingEntity> get upcomingApproved =>
      bookings.where((b) => b.isApproved).toList(growable: false);

  /// Upcoming → Cancelled sub-tab (`booking_status: cancelled`).
  List<MyBookingEntity> get upcomingCancelled =>
      bookings.where((b) => b.isCancelled).toList(growable: false);

  /// The list backing the currently selected Upcoming sub-tab.
  List<MyBookingEntity> get upcomingForFilter {
    switch (upcomingFilter) {
      case UpcomingFilter.approved:
        return upcomingApproved;
      case UpcomingFilter.cancelled:
        return upcomingCancelled;
    }
  }

  bool isActionInProgress(int bookingId) => actionBookingId == bookingId;

  MyBookingsState copyWith({
    MyBookingsStatus? status,
    String? error,
    bool clearError = false,
    List<MyBookingEntity>? bookings,
    BookingTab? selectedTab,
    UpcomingFilter? upcomingFilter,
    int? actionBookingId,
    bool clearActionBookingId = false,
    MyBookingsStatus? historyStatus,
    String? historyError,
    bool clearHistoryError = false,
    List<ChargeSessionHistoryEntity>? historySessions,
    MyBookingsStatus? liveStatus,
    String? liveError,
    bool clearLiveError = false,
    LiveSessionEntity? liveSession,
  }) {
    return MyBookingsState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      bookings: bookings ?? this.bookings,
      selectedTab: selectedTab ?? this.selectedTab,
      upcomingFilter: upcomingFilter ?? this.upcomingFilter,
      actionBookingId: clearActionBookingId
          ? null
          : (actionBookingId ?? this.actionBookingId),
      historyStatus: historyStatus ?? this.historyStatus,
      historyError:
          clearHistoryError ? null : (historyError ?? this.historyError),
      historySessions: historySessions ?? this.historySessions,
      liveStatus: liveStatus ?? this.liveStatus,
      liveError: clearLiveError ? null : (liveError ?? this.liveError),
      liveSession: liveSession ?? this.liveSession,
    );
  }

  @override
  List<Object?> get props => [
        status,
        error,
        bookings,
        selectedTab,
        upcomingFilter,
        actionBookingId,
        historyStatus,
        historyError,
        historySessions,
        liveStatus,
        liveError,
        liveSession,
      ];
}
