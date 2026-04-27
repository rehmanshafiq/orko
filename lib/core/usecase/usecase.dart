import 'package:orko_hubco/core/error/failures.dart';

/// Generic Either type — Right for success, Left for failure.
/// We roll our own to avoid adding the dartz dependency.
sealed class Either<L, R> {
  const Either();

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight);

  bool get isLeft;
  bool get isRight;

  R getOrElse(R Function() orElse);
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      onLeft(value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  R getOrElse(R Function() orElse) => orElse();
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      onRight(value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  R getOrElse(R Function() orElse) => value;
}

/// Base use case contract.
/// [T] is the return type, [Params] is the input parameter type.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use when the use case requires no parameters.
class NoParams {
  const NoParams();
}
