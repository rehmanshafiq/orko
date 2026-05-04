import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfileUseCase;

  ProfileCubit({required GetProfileUseCase getProfileUseCase})
      : _getProfileUseCase = getProfileUseCase,
        super(const ProfileInitial());

  Future<void> loadProfile() async {
    emit(const ProfileLoading());

    final result = await _getProfileUseCase(const NoParams());

    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  void setMainTab(ProfileMainTab tab) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(mainTab: tab));
  }

  void setLanguage(ProfileLanguage language) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(language: language));
  }

  void setNotifyChargingUpdates(bool value) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(notifyChargingUpdates: value));
  }

  void setNotifyBookingReminders(bool value) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(notifyBookingReminders: value));
  }

  void setNotifyPromotionalOffers(bool value) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(notifyPromotionalOffers: value));
  }

  void setNotifyAppUpdates(bool value) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(notifyAppUpdates: value));
  }
}
