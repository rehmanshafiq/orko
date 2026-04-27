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
}
