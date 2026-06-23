import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';

enum NotificationPreferencesStatus { initial, loading, success, failure }

class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.status = NotificationPreferencesStatus.initial,
    this.preferences = const NotificationPreferencesEntity.allOn(),
    this.updating = const {},
    this.errorMessage,
    this.actionError,
  });

  final NotificationPreferencesStatus status;
  final NotificationPreferencesEntity preferences;

  /// Keys whose PATCH is currently in flight (their row is locked).
  final Set<NotificationPreferenceKey> updating;

  /// Fatal error for the initial load (drives the inline error + retry).
  final String? errorMessage;

  /// Transient toggle error (drives a one-shot snackbar + revert).
  final String? actionError;

  bool isUpdating(NotificationPreferenceKey key) => updating.contains(key);

  NotificationPreferencesState copyWith({
    NotificationPreferencesStatus? status,
    NotificationPreferencesEntity? preferences,
    Set<NotificationPreferenceKey>? updating,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return NotificationPreferencesState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      updating: updating ?? this.updating,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props =>
      [status, preferences, updating, errorMessage, actionError];
}
