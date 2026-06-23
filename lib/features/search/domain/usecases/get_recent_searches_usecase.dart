import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/domain/entities/recent_search_entity.dart';
import 'package:orko_hubco/features/search/domain/repositories/search_repository.dart';

class GetRecentSearchesUseCase
    implements UseCase<List<RecentSearchEntity>, NoParams> {
  final SearchRepository repository;

  const GetRecentSearchesUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> call(NoParams params) {
    return repository.getRecentSearches();
  }
}
