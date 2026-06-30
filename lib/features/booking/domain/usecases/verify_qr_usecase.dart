import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/verify_qr_result_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class VerifyQrUseCase implements UseCase<VerifyQrResultEntity, VerifyQrParams> {
  final BookingRepository repository;

  const VerifyQrUseCase(this.repository);

  @override
  Future<Either<Failure, VerifyQrResultEntity>> call(VerifyQrParams params) {
    return repository.verifyQr(
      bookingCode: params.bookingCode,
      chargePointId: params.chargePointId,
      connectorId: params.connectorId,
    );
  }
}

class VerifyQrParams {
  const VerifyQrParams({
    required this.bookingCode,
    required this.chargePointId,
    required this.connectorId,
  });

  final String bookingCode;
  final String chargePointId;
  final int connectorId;
}
