import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

/// Upserts the FCM device token for the current user (call on token refresh).
class RegisterDeviceTokenUseCase implements UseCase<bool, String> {
  const RegisterDeviceTokenUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, bool>> call(String token) {
    return _repository.registerDeviceToken(token);
  }
}
