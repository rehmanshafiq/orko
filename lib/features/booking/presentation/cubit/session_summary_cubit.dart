import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/error/failures.dart';
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
  })  : _sessionId = sessionId,
        _getChargeSessionDetailsUseCase = getChargeSessionDetailsUseCase,
        _downloadReceiptUseCase = downloadReceiptUseCase,
        super(const SessionSummaryState());

  final int _sessionId;
  final GetChargeSessionDetailsUseCase _getChargeSessionDetailsUseCase;
  final DownloadReceiptUseCase _downloadReceiptUseCase;

  /// Resolves the temporary download URL of this session's PDF receipt via
  /// `download-receipt/<sessionId>`. Returns the URL on success, or a [Failure]
  /// the caller can surface. This is a one-shot action, so it deliberately
  /// doesn't touch the summary state — the button owns its own progress UI.
  Future<Either<Failure, String>> fetchReceiptUrl() {
    return _downloadReceiptUseCase(
      DownloadReceiptParams(sessionId: _sessionId),
    );
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
