import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

class MarkAllNotificationsReadUseCase implements UseCase<bool, NoParams> {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.markAllRead();
  }
}
