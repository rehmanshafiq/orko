import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/notifications/data/datasources/remote/notification_remote_datasource.dart';
import 'package:orko_hubco/features/notifications/data/datasources/remote/notification_remote_datasource_impl.dart';
import 'package:orko_hubco/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:orko_hubco/features/notifications/domain/repositories/notification_repository.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/delete_device_token_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_notification_preferences_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/register_device_token_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/update_notification_preferences_usecase.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notifications_cubit.dart';

void initNotificationDependencies() {
  // Data source
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNotificationPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDeviceTokenUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDeviceTokenUseCase(sl()));

  // Cubits (fresh instance per screen)
  sl.registerFactory(
    () => NotificationsCubit(
      getNotifications: sl(),
      getUnreadCount: sl(),
      markRead: sl(),
      markAllRead: sl(),
    ),
  );
  sl.registerFactory(
    () => NotificationPreferencesCubit(
      getPreferences: sl(),
      updatePreferences: sl(),
    ),
  );
}
