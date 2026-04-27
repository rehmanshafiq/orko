import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/remote_config/domain/usecases/fetch_remote_config_usecase.dart';
import 'package:orko_hubco/features/remote_config/presentation/cubit/remote_config_state.dart';

class RemoteConfigCubit extends Cubit<RemoteConfigState> {
  final FetchRemoteConfigUseCase _fetchConfigUseCase;

  RemoteConfigCubit({required FetchRemoteConfigUseCase fetchConfigUseCase})
      : _fetchConfigUseCase = fetchConfigUseCase,
        super(const RemoteConfigInitial());

  Future<void> fetchConfig() async {
    emit(const RemoteConfigLoading());

    final result = await _fetchConfigUseCase(const NoParams());

    result.fold(
      (failure) => emit(RemoteConfigError(failure.message)),
      (config) => emit(RemoteConfigLoaded(config)),
    );
  }
}
