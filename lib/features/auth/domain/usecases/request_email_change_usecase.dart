import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Step 1 of the email-change flow: requests an OTP be sent to the new email
/// (`change_email`). Returns the issued `otp_id`.
class RequestEmailChangeUseCase
    implements UseCase<int, RequestEmailChangeParams> {
  final AuthRepository repository;

  const RequestEmailChangeUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(RequestEmailChangeParams params) {
    return repository.requestEmailChange(params.email);
  }
}

class RequestEmailChangeParams {
  const RequestEmailChangeParams({required this.email});

  final String email;
}
