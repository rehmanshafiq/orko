import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/booking/data/datasources/remote/booking_remote_datasource.dart';
import 'package:orko_hubco/features/booking/data/datasources/remote/booking_remote_datasource_impl.dart';
import 'package:orko_hubco/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';
import 'package:orko_hubco/features/booking/domain/usecases/cancel_booking_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/create_booking_hgl_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/create_booking_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_booking_slots_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_charge_session_history_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_charger_details_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_my_bookings_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/reschedule_booking_usecase.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_cubit.dart';

void initBookingDependencies() {
  // Data source
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetChargerDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingSlotsUseCase(sl()));
  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => CreateBookingHglUseCase(sl()));
  sl.registerLazySingleton(() => GetMyBookingsUseCase(sl()));
  sl.registerLazySingleton(() => GetChargeSessionHistoryUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton(() => RescheduleBookingUseCase(sl()));

  // Cubit (new instance per booking screen).
  // Booking goes through `book-charge-session` (no end_time), i.e. the HGL
  // use case, per the backend contract.
  sl.registerFactory(
    () => BookingCubit(
      getChargerDetailsUseCase: sl(),
      getSlotsUseCase: sl(),
      createBookingUseCase: sl<CreateBookingHglUseCase>(),
    ),
  );

  sl.registerFactory(
    () => MyBookingsCubit(
      getMyBookingsUseCase: sl(),
      getChargeSessionHistoryUseCase: sl(),
      cancelBookingUseCase: sl(),
      rescheduleBookingUseCase: sl(),
    ),
  );
}
