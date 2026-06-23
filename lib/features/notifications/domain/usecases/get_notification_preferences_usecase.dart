import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationPreferencesUseCase
    implements UseCase<NotificationPreferencesEntity, NoParams> {
  const GetNotificationPreferencesUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> call(NoParams params) {
    return _repository.getPreferences();
  }
}
