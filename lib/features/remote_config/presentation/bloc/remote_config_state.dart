import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';

sealed class RemoteConfigState extends Equatable {
  const RemoteConfigState();

  @override
  List<Object?> get props => [];
}

class RemoteConfigInitial extends RemoteConfigState {
  const RemoteConfigInitial();
}

class RemoteConfigLoading extends RemoteConfigState {
  const RemoteConfigLoading();
}

class RemoteConfigLoaded extends RemoteConfigState {
  const RemoteConfigLoaded(this.model);

  final RemoteConfigModel model;

  @override
  List<Object?> get props => [model];
}

class RemoteConfigError extends RemoteConfigState {
  const RemoteConfigError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
