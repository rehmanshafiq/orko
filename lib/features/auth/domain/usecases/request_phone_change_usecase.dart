import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Step 1 of the phone-change flow: requests an OTP be sent to the new number
/// (`change_phone`). Returns the `otp_id` needed to verify.
class RequestPhoneChangeUseCase
    implements UseCase<int, RequestPhoneChangeParams> {
  final AuthRepository repository;

  const RequestPhoneChangeUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(RequestPhoneChangeParams params) {
    return repository.requestPhoneChange(
      phoneNumber: params.phoneNumber,
      countryCode: params.countryCode,
    );
  }
}

class RequestPhoneChangeParams {
  const RequestPhoneChangeParams({
    required this.phoneNumber,
    required this.countryCode,
  });

  final String phoneNumber;
  final String countryCode;
}
