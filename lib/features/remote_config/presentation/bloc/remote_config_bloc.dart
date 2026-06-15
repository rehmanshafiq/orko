import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/remote_config/presentation/bloc/remote_config_event.dart';
import 'package:orko_hubco/features/remote_config/presentation/bloc/remote_config_state.dart';

/// Drives remote config resolution through [RemoteConfigService].
///
/// A failure in Firebase alone never surfaces as an error state; the bloc only
/// emits [RemoteConfigError] when every fallback layer fails.
class RemoteConfigBloc extends Bloc<RemoteConfigEvent, RemoteConfigState> {
  RemoteConfigBloc({RemoteConfigService? service})
      : _service = service ?? RemoteConfigService.instance,
        super(const RemoteConfigInitial()) {
    on<RemoteConfigLoadRequested>(_onLoadRequested);
  }

  final RemoteConfigService _service;

  Future<void> _onLoadRequested(
    RemoteConfigLoadRequested event,
    Emitter<RemoteConfigState> emit,
  ) async {
    emit(const RemoteConfigLoading());

    try {
      final model = await _service.initialize(forceRefresh: event.forceRefresh);
      emit(RemoteConfigLoaded(model));
    } catch (error) {
      emit(RemoteConfigError(error.toString()));
    }
  }
}
