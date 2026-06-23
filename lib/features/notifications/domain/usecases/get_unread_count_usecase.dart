import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

class GetUnreadCountUseCase implements UseCase<int, NoParams> {
  const GetUnreadCountUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) {
    return _repository.getUnreadCount();
  }
}
