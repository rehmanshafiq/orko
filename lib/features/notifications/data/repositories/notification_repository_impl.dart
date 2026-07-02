import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/data/datasources/remote/notification_remote_datasource.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_page_entity.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, NotificationPageEntity>> getNotifications({
    required int page,
    required int pageSize,
  }) {
    return _run(
      () => remoteDataSource.getNotifications(page: page, pageSize: pageSize),
    );
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() {
    return _run(() => remoteDataSource.getUnreadCount());
  }

  @override
  Future<Either<Failure, bool>> markRead(int id) {
    return _run(() => remoteDataSource.markRead(id));
  }

  @override
  Future<Either<Failure, bool>> markAllRead() {
    return _run(() => remoteDataSource.markAllRead());
  }

  @override
  Future<Either<Failure, bool>> clearAll() {
    return _run(() => remoteDataSource.clearAll());
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences() {
    return _run(() => remoteDataSource.getPreferences());
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> updatePreferences(
    Map<String, bool> changes,
  ) {
    return _run(() => remoteDataSource.updatePreferences(changes));
  }

  @override
  Future<Either<Failure, bool>> registerDeviceToken(String token) {
    return _run(() => remoteDataSource.registerDeviceToken(token));
  }

  @override
  Future<Either<Failure, bool>> deleteDeviceToken() {
    return _run(() => remoteDataSource.deleteDeviceToken());
  }

  /// Shared connectivity guard + exception→failure mapping for every call.
  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      return Right(await action());
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
