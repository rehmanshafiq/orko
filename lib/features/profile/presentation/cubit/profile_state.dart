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
  final bool notifyChargingUpdates;
  final bool notifyBookingReminders;
  final bool notifyPromotionalOffers;
  final bool notifyAppUpdates;

  const ProfileLoaded(
    this.profile, {
    this.mainTab = ProfileMainTab.profile,
    this.language = ProfileLanguage.english,
    this.notifyChargingUpdates = true,
    this.notifyBookingReminders = true,
    this.notifyPromotionalOffers = false,
    this.notifyAppUpdates = true,
  });

  ProfileLoaded copyWith({
    ProfileEntity? profile,
    ProfileMainTab? mainTab,
    ProfileLanguage? language,
    bool? notifyChargingUpdates,
    bool? notifyBookingReminders,
    bool? notifyPromotionalOffers,
    bool? notifyAppUpdates,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      mainTab: mainTab ?? this.mainTab,
      language: language ?? this.language,
      notifyChargingUpdates:
          notifyChargingUpdates ?? this.notifyChargingUpdates,
      notifyBookingReminders:
          notifyBookingReminders ?? this.notifyBookingReminders,
      notifyPromotionalOffers:
          notifyPromotionalOffers ?? this.notifyPromotionalOffers,
      notifyAppUpdates: notifyAppUpdates ?? this.notifyAppUpdates,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        mainTab,
        language,
        notifyChargingUpdates,
        notifyBookingReminders,
        notifyPromotionalOffers,
        notifyAppUpdates,
      ];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
