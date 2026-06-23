import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

/// Clears the FCM device token for the current user (call on logout).
class DeleteDeviceTokenUseCase implements UseCase<bool, NoParams> {
  const DeleteDeviceTokenUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.deleteDeviceToken();
  }
}
