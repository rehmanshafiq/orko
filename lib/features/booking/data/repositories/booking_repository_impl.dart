import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/data/datasources/remote/booking_remote_datasource.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/charger_details_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const BookingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ChargerDetailsEntity>> getChargerDetails({
    required int locationId,
  }) {
    return _run(() => remoteDataSource.getChargerDetails(locationId: locationId));
  }

  @override
  Future<Either<Failure, List<BookingSlotEntity>>> getSlots({
    required String date,
    required int locationId,
  }) {
    return _run(() => remoteDataSource.getSlots(date: date, locationId: locationId));
  }

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String bookingDate,
    required String startTime,
    required String endTime,
    required int location,
  }) {
    return _run(
      () => remoteDataSource.createBooking(
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
        location: location,
      ),
    );
  }

  @override
  Future<Either<Failure, BookingEntity>> createBookingHgl({
    required String bookingDate,
    required String startTime,
    required int location,
    int? vehicleId,
  }) {
    return _run(
      () => remoteDataSource.createBookingHgl(
        bookingDate: bookingDate,
        startTime: startTime,
        location: location,
        vehicleId: vehicleId,
      ),
    );
  }

  @override
  Future<Either<Failure, List<MyBookingEntity>>> getMyBookings() {
    return _run(() => remoteDataSource.getMyBookings());
  }

  @override
  Future<Either<Failure, List<ChargeSessionHistoryEntity>>>
      getChargeSessionHistory() {
    return _run(() => remoteDataSource.getChargeSessionHistory());
  }

  @override
  Future<Either<Failure, LiveSessionEntity>> getLiveSession() {
    return _run(() => remoteDataSource.getLiveSession());
  }

  @override
  Future<Either<Failure, String>> cancelBooking({required int bookingId}) {
    return _run(() => remoteDataSource.cancelBooking(bookingId: bookingId));
  }

  @override
  Future<Either<Failure, BookingEntity>> rescheduleBooking({
    required int bookingId,
    required String bookingDate,
    required String startTime,
    required int location,
  }) {
    return _run(
      () => remoteDataSource.rescheduleBooking(
        bookingId: bookingId,
        bookingDate: bookingDate,
        startTime: startTime,
        location: location,
      ),
    );
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
