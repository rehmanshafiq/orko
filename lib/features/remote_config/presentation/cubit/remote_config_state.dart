import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/remote_config/domain/entities/remote_config_entity.dart';

abstract class RemoteConfigState extends Equatable {
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
  final RemoteConfigEntity config;

  const RemoteConfigLoaded(this.config);

  @override
  List<Object?> get props => [config];
}

class RemoteConfigError extends RemoteConfigState {
  final String message;

  const RemoteConfigError(this.message);

  @override
  List<Object?> get props => [message];
}
