import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/support/domain/entities/support_category_entity.dart';
import 'package:orko_hubco/features/support/domain/repositories/support_repository.dart';

/// Fetches the backend-driven support ticket categories
/// (`GET api/v1/cvp/cvp-support-ticket/categories/`).
class GetSupportCategoriesUseCase
    implements UseCase<List<SupportCategoryEntity>, NoParams> {
  final SupportRepository repository;

  const GetSupportCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<SupportCategoryEntity>>> call(NoParams params) {
    return repository.getCategories();
  }
}
