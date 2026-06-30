import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_notification_preferences_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/update_notification_preferences_usecase.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notification_preferences_state.dart';

class NotificationPreferencesCubit
    extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    required GetNotificationPreferencesUseCase getPreferences,
    required UpdateNotificationPreferencesUseCase updatePreferences,
  })  : _getPreferences = getPreferences,
        _updatePreferences = updatePreferences,
        super(const NotificationPreferencesState());

  final GetNotificationPreferencesUseCase _getPreferences;
  final UpdateNotificationPreferencesUseCase _updatePreferences;

  Future<void> load() async {
    if (state.status == NotificationPreferencesStatus.loading) return;
    emit(state.copyWith(
      status: NotificationPreferencesStatus.loading,
      clearErrorMessage: true,
      clearActionError: true,
    ));

    final result = await _getPreferences(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationPreferencesStatus.failure,
        errorMessage: failure.message,
      )),
      (prefs) => emit(state.copyWith(
        status: NotificationPreferencesStatus.success,
        preferences: prefs,
        clearErrorMessage: true,
      )),
    );
  }

  /// Master on/off: optimistically sets every category to [value] and PATCHes
  /// them in a single request, reverting on failure. Ignores re-taps while any
  /// toggle is still in flight, and is a no-op when nothing would change.
  Future<void> setAll(bool value) async {
    if (state.updating.isNotEmpty) return;

    final previous = state.preferences;
    if (NotificationPreferenceKey.values
        .every((k) => previous.valueOf(k) == value)) {
      return;
    }

    emit(state.copyWith(
      preferences: previous.copyWithAll(value),
      updating: NotificationPreferenceKey.values.toSet(),
      clearActionError: true,
    ));

    final result = await _updatePreferences(
      UpdateNotificationPreferencesParams({
        for (final k in NotificationPreferenceKey.values) k.apiKey: value,
      }),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        preferences: previous, // revert
        updating: const {},
        actionError: failure.message,
      )),
      (serverPrefs) => emit(state.copyWith(
        preferences: serverPrefs, // server is authoritative
        updating: const {},
      )),
    );
  }

  /// Optimistically flips [key], PATCHes only that field, and reconciles with
  /// the server response. Reverts the toggle if the request fails. Ignores
  /// re-taps while the same key is still in flight.
  Future<void> toggle(NotificationPreferenceKey key, bool value) async {
    if (state.isUpdating(key)) return;
    if (state.preferences.valueOf(key) == value) return;

    final previous = state.preferences;

    emit(state.copyWith(
      preferences: previous.copyWithKey(key, value),
      updating: {...state.updating, key},
      clearActionError: true,
    ));

    final result = await _updatePreferences(
      UpdateNotificationPreferencesParams({key.apiKey: value}),
    );

    final nextUpdating = {...state.updating}..remove(key);
    result.fold(
      (failure) => emit(state.copyWith(
        preferences: previous, // revert
        updating: nextUpdating,
        actionError: failure.message,
      )),
      (serverPrefs) => emit(state.copyWith(
        preferences: serverPrefs, // server is authoritative
        updating: nextUpdating,
      )),
    );
  }
}
