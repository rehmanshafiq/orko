import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_detail_entity.dart';

/// Lifecycle of the charge-session-details fetch behind the summary screen.
enum SessionSummaryStatus { loading, success, failure }

class SessionSummaryState extends Equatable {
  const SessionSummaryState({
    this.status = SessionSummaryStatus.loading,
    this.detail,
    this.error,
  });

  final SessionSummaryStatus status;

  /// The loaded session details; null until the fetch succeeds.
  final ChargeSessionDetailEntity? detail;

  final String? error;

  bool get isLoading => status == SessionSummaryStatus.loading;
  bool get isFailure => status == SessionSummaryStatus.failure;

  SessionSummaryState copyWith({
    SessionSummaryStatus? status,
    ChargeSessionDetailEntity? detail,
    String? error,
    bool clearError = false,
  }) {
    return SessionSummaryState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, detail, error];
}
