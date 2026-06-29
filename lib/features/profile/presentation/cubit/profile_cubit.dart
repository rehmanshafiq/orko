import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileInitial());

  /// The profile screen renders from the persisted user (`getUser`) and the
  /// `charging_stats` API — it no longer fetches a separate profile object, so
  /// this just drops into the loaded state with an empty placeholder. (The old
  /// implementation hit the postman-echo mock endpoint on every tab open.)
  void loadProfile() {
    emit(const ProfileLoaded(
      ProfileEntity(id: '', name: '', email: ''),
    ));
  }

  void setMainTab(ProfileMainTab tab) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(mainTab: tab));
  }

  /// Forces a rebuild after the cached user changed (profile edit / picture
  /// upload) without a full reload flash.
  void notifyUserUpdated() {
    final s = state;
    if (s is ProfileLoaded) {
      emit(s.copyWith(userRevision: s.userRevision + 1));
    }
  }

  void setLanguage(ProfileLanguage language) {
    final s = state;
    if (s is ProfileLoaded) emit(s.copyWith(language: language));
  }
}
