import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationReadUseCase implements UseCase<bool, int> {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, bool>> call(int id) {
    return _repository.markRead(id);
  }
}
