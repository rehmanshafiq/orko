import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/onboarding/domain/entities/onboarding_item_entity.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.items = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isCompleting = false,
    this.isCompleted = false,
    this.errorMessage,
  });

  final List<OnboardingItemEntity> items;
  final int currentIndex;
  final bool isLoading;
  final bool isCompleting;
  final bool isCompleted;
  final String? errorMessage;

  bool get isLastPage => items.isNotEmpty && currentIndex == items.length - 1;

  OnboardingState copyWith({
    List<OnboardingItemEntity>? items,
    int? currentIndex,
    bool? isLoading,
    bool? isCompleting,
    bool? isCompleted,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return OnboardingState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      isCompleting: isCompleting ?? this.isCompleting,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentIndex,
        isLoading,
        isCompleting,
        isCompleted,
        errorMessage,
      ];
}
