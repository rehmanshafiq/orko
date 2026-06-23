import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/domain/repositories/search_repository.dart';

class ClearRecentSearchesUseCase implements UseCase<void, NoParams> {
  final SearchRepository repository;

  const ClearRecentSearchesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.clearRecentSearches();
  }
}
