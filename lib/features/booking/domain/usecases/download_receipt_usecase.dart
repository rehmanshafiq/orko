import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

/// Fetches the temporary URL of the generated PDF receipt for a finished
/// charging session (`download-receipt/<sessionId>`).
class DownloadReceiptUseCase implements UseCase<String, DownloadReceiptParams> {
  final BookingRepository repository;

  const DownloadReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(DownloadReceiptParams params) {
    return repository.getReceiptUrl(sessionId: params.sessionId);
  }
}

class DownloadReceiptParams {
  const DownloadReceiptParams({required this.sessionId});

  final int sessionId;
}
