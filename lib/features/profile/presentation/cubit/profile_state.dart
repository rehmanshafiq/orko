import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';

/// Top-level tabs under the profile header (matches account hub layout).
enum ProfileMainTab {
  profile,
  vehicles,
  settings,
}

/// Language segment for the settings tab.
enum ProfileLanguage {
  english,
  urdu,
}

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final ProfileMainTab mainTab;
  final ProfileLanguage language;

  const ProfileLoaded(
    this.profile, {
    this.mainTab = ProfileMainTab.profile,
    this.language = ProfileLanguage.english,
  });

  ProfileLoaded copyWith({
    ProfileEntity? profile,
    ProfileMainTab? mainTab,
    ProfileLanguage? language,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      mainTab: mainTab ?? this.mainTab,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [profile, mainTab, language];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
