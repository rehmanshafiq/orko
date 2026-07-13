import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/support/domain/entities/support_ticket_entity.dart';
import 'package:orko_hubco/features/support/domain/repositories/support_repository.dart';

/// Creates a support ticket (`POST api/v1/cvp/cvp-support-ticket/`).
class CreateSupportTicketUseCase
    implements UseCase<SupportTicketEntity, CreateSupportTicketParams> {
  final SupportRepository repository;

  const CreateSupportTicketUseCase(this.repository);

  @override
  Future<Either<Failure, SupportTicketEntity>> call(
    CreateSupportTicketParams params,
  ) {
    return repository.createTicket(
      categoryValue: params.categoryValue,
      description: params.description,
      attachmentPaths: params.attachmentPaths,
    );
  }
}

class CreateSupportTicketParams extends Equatable {
  const CreateSupportTicketParams({
    required this.categoryValue,
    required this.description,
    this.attachmentPaths = const [],
  });

  /// Backend DB value (snake_case) for the chosen category.
  final String categoryValue;
  final String description;
  final List<String> attachmentPaths;

  @override
  List<Object?> get props => [categoryValue, description, attachmentPaths];
}
