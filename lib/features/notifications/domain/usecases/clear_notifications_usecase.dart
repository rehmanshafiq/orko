import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

/// Permanently deletes every notification for the user (`DELETE
/// notifications/`).
class ClearNotificationsUseCase implements UseCase<bool, NoParams> {
  const ClearNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.clearAll();
  }
}
