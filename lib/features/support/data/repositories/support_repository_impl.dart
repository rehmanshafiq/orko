import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/support/data/datasources/remote/support_remote_datasource.dart';
import 'package:orko_hubco/features/support/domain/entities/support_category_entity.dart';
import 'package:orko_hubco/features/support/domain/entities/support_ticket_entity.dart';
import 'package:orko_hubco/features/support/domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const SupportRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<SupportCategoryEntity>>> getCategories() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final categories = await remoteDataSource.getCategories();
      return Right(categories);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupportTicketEntity>> createTicket({
    required String categoryValue,
    required String description,
    List<String> attachmentPaths = const [],
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final ticket = await remoteDataSource.createTicket(
        category: categoryValue,
        description: description,
        attachmentPaths: attachmentPaths,
      );
      return Right(ticket);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
