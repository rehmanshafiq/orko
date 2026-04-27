import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:orko_hubco/features/onboarding/domain/usecases/get_onboarding_items_usecase.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required GetOnboardingItemsUseCase getOnboardingItemsUseCase,
    required CompleteOnboardingUseCase completeOnboardingUseCase,
  })  : _getOnboardingItemsUseCase = getOnboardingItemsUseCase,
        _completeOnboardingUseCase = completeOnboardingUseCase,
        super(const OnboardingState());

  final GetOnboardingItemsUseCase _getOnboardingItemsUseCase;
  final CompleteOnboardingUseCase _completeOnboardingUseCase;

  Future<void> loadSlides() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    final result = await _getOnboardingItemsUseCase(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          isLoading: false,
          items: items,
          currentIndex: 0,
          clearErrorMessage: true,
        ),
      ),
    );
  }

  void setCurrentIndex(int index) {
    if (index == state.currentIndex) return;
    emit(state.copyWith(currentIndex: index, clearErrorMessage: true));
  }

  Future<void> complete() async {
    if (state.isCompleting) return;
    emit(state.copyWith(isCompleting: true, clearErrorMessage: true));

    final result = await _completeOnboardingUseCase(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          isCompleting: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isCompleting: false,
          isCompleted: true,
          clearErrorMessage: true,
        ),
      ),
    );
  }
}
