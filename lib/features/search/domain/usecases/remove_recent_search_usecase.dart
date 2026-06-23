import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/domain/entities/recent_search_entity.dart';
import 'package:orko_hubco/features/search/domain/repositories/search_repository.dart';

class RemoveRecentSearchUseCase
    implements UseCase<List<RecentSearchEntity>, String> {
  final SearchRepository repository;

  const RemoveRecentSearchUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> call(String query) {
    return repository.removeRecentSearch(query);
  }
}
