import 'package:equatable/equatable.dart';

/// Remote config domain entity.
class RemoteConfigEntity extends Equatable {
  final bool maintenanceMode;
  final String minimumAppVersion;
  final bool forceUpdate;
  final String? promoMessage;
  final Map<String, dynamic> featureFlags;

  const RemoteConfigEntity({
    required this.maintenanceMode,
    required this.minimumAppVersion,
    required this.forceUpdate,
    this.promoMessage,
    this.featureFlags = const {},
  });

  /// Check if a specific feature flag is enabled.
  bool isFeatureEnabled(String key) {
    return featureFlags[key] == true;
  }

  @override
  List<Object?> get props => [
        maintenanceMode,
        minimumAppVersion,
        forceUpdate,
        promoMessage,
        featureFlags,
      ];
}
