import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:orko_hubco/features/support/domain/usecases/get_support_categories_usecase.dart';
import 'package:orko_hubco/features/support/presentation/cubit/support_ticket_state.dart';

class SupportTicketCubit extends Cubit<SupportTicketState> {
  SupportTicketCubit({
    required CreateSupportTicketUseCase createTicket,
    required GetSupportCategoriesUseCase getCategories,
  })  : _createTicket = createTicket,
        _getCategories = getCategories,
        super(const SupportTicketState());

  final CreateSupportTicketUseCase _createTicket;
  final GetSupportCategoriesUseCase _getCategories;

  /// Loads the backend-driven category list. Called on screen open and retry.
  Future<void> loadCategories() async {
    if (state.categoriesLoading) return;
    emit(state.copyWith(
      categoriesStatus: SupportCategoriesStatus.loading,
      categoriesError: null,
    ));

    final result = await _getCategories(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        categoriesStatus: SupportCategoriesStatus.failure,
        categoriesError: failure.message,
      )),
      (categories) => emit(state.copyWith(
        categoriesStatus: SupportCategoriesStatus.success,
        categories: categories,
      )),
    );
  }

  Future<void> submit({
    required String categoryValue,
    required String description,
    List<String> attachmentPaths = const [],
  }) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(status: SupportTicketStatus.submitting));

    final result = await _createTicket(
      CreateSupportTicketParams(
        categoryValue: categoryValue,
        description: description,
        attachmentPaths: attachmentPaths,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: SupportTicketStatus.failure,
        error: failure.message,
      )),
      (ticket) => emit(state.copyWith(
        status: SupportTicketStatus.success,
        ticket: ticket,
      )),
    );
  }
}
