import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

class UpdateNotificationPreferencesParams extends Equatable {
  const UpdateNotificationPreferencesParams(this.changes);

  /// Maps API field names (e.g. `charging_updates`) to their new value.
  final Map<String, bool> changes;

  @override
  List<Object?> get props => [changes];
}

class UpdateNotificationPreferencesUseCase
    implements
        UseCase<NotificationPreferencesEntity,
            UpdateNotificationPreferencesParams> {
  const UpdateNotificationPreferencesUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> call(
    UpdateNotificationPreferencesParams params,
  ) {
    return _repository.updatePreferences(params.changes);
  }
}
