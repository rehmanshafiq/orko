import 'package:equatable/equatable.dart';

sealed class RemoteConfigEvent extends Equatable {
  const RemoteConfigEvent();

  @override
  List<Object?> get props => [];
}

/// Requests resolution of the remote config via the multi-layer fallback.
class RemoteConfigLoadRequested extends RemoteConfigEvent {
  const RemoteConfigLoadRequested({this.forceRefresh = false});

  /// Forces a fresh Firebase fetch, bypassing the in-memory cache.
  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}
