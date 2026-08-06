import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/booking/domain/usecases/download_receipt_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_charge_session_details_usecase.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/session_summary_state.dart';

/// Loads the details of one finished charging session for the post-session
/// summary screen (`charge-session-details`).
class SessionSummaryCubit extends Cubit<SessionSummaryState> {
  SessionSummaryCubit({
    required int sessionId,
    required GetChargeSessionDetailsUseCase getChargeSessionDetailsUseCase,
    required DownloadReceiptUseCase downloadReceiptUseCase,
    required AnalyticsService analytics,
  })  : _sessionId = sessionId,
        _getChargeSessionDetailsUseCase = getChargeSessionDetailsUseCase,
        _downloadReceiptUseCase = downloadReceiptUseCase,
        _analytics = analytics,
        super(const SessionSummaryState());

  final int _sessionId;
  final GetChargeSessionDetailsUseCase _getChargeSessionDetailsUseCase;
  final DownloadReceiptUseCase _downloadReceiptUseCase;
  final AnalyticsService _analytics;

  /// Resolves the temporary download URL of this session's PDF receipt via
  /// `download-receipt/<sessionId>`. Returns the URL on success, or a [Failure]
  /// the caller can surface. This is a one-shot action, so it deliberately
  /// doesn't touch the summary state — the button owns its own progress UI.
  Future<Either<Failure, String>> fetchReceiptUrl() {
    return _downloadReceiptUseCase(
      DownloadReceiptParams(sessionId: _sessionId),
    );
  }

  /// Logs that the user chose to settle at the station. [method] is the picked
  /// settlement method (`cash` / `credit`).
  void logPayAtStationSelected(String method) {
    _analytics.logEvent('pay_at_station_selected', parameters: {
      'method': method,
      'session_id': _sessionId,
    });
  }

  /// Logs a tap on the in-app pay button, which is not live yet — [outcome]
  /// records why nothing happened (currently always `coming_soon`).
  void logPayInAppTapped({String outcome = 'coming_soon'}) {
    _analytics.logEvent('pay_in_app_tapped', parameters: {
      'outcome': outcome,
      'session_id': _sessionId,
    });
  }

  /// Logs a receipt that was successfully fetched and handed to the share sheet.
  void logReceiptDownloaded() {
    _analytics.logEvent('receipt_downloaded', parameters: {
      'session_id': _sessionId,
    });
  }

  Future<void> load() async {
    emit(state.copyWith(
      status: SessionSummaryStatus.loading,
      clearError: true,
    ));

    final result = await _getChargeSessionDetailsUseCase(
      GetChargeSessionDetailsParams(sessionId: _sessionId),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SessionSummaryStatus.failure,
          error: failure.message,
        ),
      ),
      (detail) {
        // Fire the core revenue event only when THIS load corresponds to the
        // session that just finished live (its id is still the persisted active
        // one). Opening the same summary later from history leaves the persisted
        // id null, so the purchase-equivalent event isn't double-counted.
        if (AppStorage.activeChargeSessionId == _sessionId) {
          _analytics.logEvent(
            'charging_session_completed',
            parameters: {
              'session_id': detail.id,
              'energy_kwh': detail.energyConsumed,
              'total_cost': detail.totalCost,
              'energy_cost': detail.energyCost,
              'co2_reduced_kg': detail.co2ReducedKg,
              // Costs on this entity are documented as PKR (no currency field).
              'currency': 'PKR',
            },
          );
        }
        // The summary reached the user — drop the pending session id now so a
        // kill-while-on-this-screen doesn't re-show it on the next launch.
        // (Dismissing the screen clears it too; this is the earlier of the
        // two.) On failure we keep the id so the summary retries next visit.
        AppStorage.clearActiveChargeSessionId();
        emit(
          state.copyWith(
            status: SessionSummaryStatus.success,
            detail: detail,
            clearError: true,
          ),
        );
      },
    );
  }
}
