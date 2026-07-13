import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/support/domain/entities/support_category_entity.dart';
import 'package:orko_hubco/features/support/domain/entities/support_ticket_entity.dart';

/// Loading state of the backend-driven category list.
enum SupportCategoriesStatus { initial, loading, success, failure }

/// Loading state of the ticket submission.
enum SupportTicketStatus { initial, submitting, success, failure }

class SupportTicketState extends Equatable {
  const SupportTicketState({
    this.categoriesStatus = SupportCategoriesStatus.initial,
    this.categories = const [],
    this.categoriesError,
    this.status = SupportTicketStatus.initial,
    this.ticket,
    this.error,
  });

  final SupportCategoriesStatus categoriesStatus;
  final List<SupportCategoryEntity> categories;
  final String? categoriesError;

  final SupportTicketStatus status;
  final SupportTicketEntity? ticket;
  final String? error;

  bool get isSubmitting => status == SupportTicketStatus.submitting;
  bool get categoriesLoading =>
      categoriesStatus == SupportCategoriesStatus.loading;
  bool get categoriesFailed =>
      categoriesStatus == SupportCategoriesStatus.failure;

  SupportTicketState copyWith({
    SupportCategoriesStatus? categoriesStatus,
    List<SupportCategoryEntity>? categories,
    String? categoriesError,
    SupportTicketStatus? status,
    SupportTicketEntity? ticket,
    String? error,
  }) {
    return SupportTicketState(
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      categories: categories ?? this.categories,
      categoriesError: categoriesError,
      status: status ?? this.status,
      ticket: ticket ?? this.ticket,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        categoriesStatus,
        categories,
        categoriesError,
        status,
        ticket,
        error,
      ];
}
