import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/support/domain/entities/support_category_entity.dart';
import 'package:orko_hubco/features/support/domain/entities/support_ticket_entity.dart';

/// Contract for raising support tickets (technical issues, complaints, etc.).
abstract class SupportRepository {
  /// Fetches the available ticket categories (backend-driven list).
  Future<Either<Failure, List<SupportCategoryEntity>>> getCategories();

  /// Creates a support ticket. [categoryValue] is the backend DB value
  /// (snake_case). [attachmentPaths] are optional local file paths
  /// (jpg/jpeg/png, up to 5, each < 2MB — validated before this is called).
  Future<Either<Failure, SupportTicketEntity>> createTicket({
    required String categoryValue,
    required String description,
    List<String> attachmentPaths,
  });
}
