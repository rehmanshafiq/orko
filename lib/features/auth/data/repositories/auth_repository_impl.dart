import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
/// Orchestrates between remote and local data sources.
/// Handles exception-to-failure mapping.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, SignUpResultEntity>> login({
    required String phoneNumber,
    required String countryCode,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await remoteDataSource.login(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        password: password,
      );

      // Persist the issued access token + user locally (same as sign-up).
      if (result.accessToken.isNotEmpty) {
        await localDataSource.cacheTokens(accessToken: result.accessToken);
      }
      await localDataSource.cacheUser(result.user as UserModel);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignUpResultEntity>> loginWithGoogle({
    required String name,
    required String email,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await remoteDataSource.loginWithGoogle(
        name: name,
        email: email,
      );

      // Persist the issued access token + user locally (same as login).
      if (result.accessToken.isNotEmpty) {
        await localDataSource.cacheTokens(accessToken: result.accessToken);
      }
      await localDataSource.cacheUser(result.user as UserModel);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );

      await localDataSource.cacheUser(user);

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SignUpResultEntity>> signUp({
    required String name,
    required String phoneNumber,
    required String countryCode,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await remoteDataSource.completeSignup(
        name: name,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      // Persist the issued access token + user locally.
      if (result.accessToken.isNotEmpty) {
        await localDataSource.cacheTokens(accessToken: result.accessToken);
      }
      await localDataSource.cacheUser(result.user as UserModel);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp({required String otp}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    final token = localDataSource.accessToken;
    if (token == null || token.isEmpty) {
      return const Left(
        UnauthorizedFailure(message: 'Session expired. Please sign up again.'),
      );
    }

    try {
      await remoteDataSource.verifyOtp(otp: otp, accessToken: token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> resendOtp({String? otpId}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    // Signup flow (no otpId) requires the JWT saved at sign-up.
    String? token;
    if (otpId == null || otpId.isEmpty) {
      token = localDataSource.accessToken;
      if (token == null || token.isEmpty) {
        return const Left(
          UnauthorizedFailure(
            message: 'Session expired. Please sign up again.',
          ),
        );
      }
    }

    try {
      final message = await remoteDataSource.resendOtp(
        otpId: otpId,
        accessToken: token,
      );
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }
      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      // Still clear local cache even if server logout fails
      await localDataSource.clearCache();
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      await localDataSource.clearCache();
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      return Right(localDataSource.hasToken);
    } catch (e) {
      return const Right(false);
    }
  }
}
