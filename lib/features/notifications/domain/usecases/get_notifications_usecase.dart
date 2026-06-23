import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_page_entity.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsParams extends Equatable {
  const GetNotificationsParams({this.page = 1, this.pageSize = 20});

  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [page, pageSize];
}

class GetNotificationsUseCase
    implements UseCase<NotificationPageEntity, GetNotificationsParams> {
  const GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Either<Failure, NotificationPageEntity>> call(
    GetNotificationsParams params,
  ) {
    return _repository.getNotifications(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
