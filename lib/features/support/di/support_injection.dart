import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/support/data/datasources/remote/support_remote_datasource.dart';
import 'package:orko_hubco/features/support/data/repositories/support_repository_impl.dart';
import 'package:orko_hubco/features/support/domain/repositories/support_repository.dart';
import 'package:orko_hubco/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:orko_hubco/features/support/domain/usecases/get_support_categories_usecase.dart';
import 'package:orko_hubco/features/support/presentation/cubit/support_ticket_cubit.dart';

/// Registers all Support feature dependencies.
void initSupportDependencies() {
  // Data Sources
  sl.registerLazySingleton<SupportRemoteDataSource>(
    () => SupportRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateSupportTicketUseCase(sl()));
  sl.registerLazySingleton(() => GetSupportCategoriesUseCase(sl()));

  // Cubit
  sl.registerFactory(
    () => SupportTicketCubit(createTicket: sl(), getCategories: sl()),
  );
}
