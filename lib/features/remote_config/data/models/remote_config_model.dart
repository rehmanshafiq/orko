import 'package:orko_hubco/features/remote_config/domain/entities/remote_config_entity.dart';

/// Remote config data model with JSON mapping from Firebase RemoteConfig.
class RemoteConfigModel extends RemoteConfigEntity {
  const RemoteConfigModel({
    required super.maintenanceMode,
    required super.minimumAppVersion,
    required super.forceUpdate,
    super.promoMessage,
    super.featureFlags,
  });

  /// Creates a [RemoteConfigModel] from Firebase RemoteConfig values.
  factory RemoteConfigModel.fromFirebase(Map<String, dynamic> values) {
    return RemoteConfigModel(
      maintenanceMode: values['maintenance_mode'] as bool? ?? false,
      minimumAppVersion: values['minimum_app_version'] as String? ?? '1.0.0',
      forceUpdate: values['force_update'] as bool? ?? false,
      promoMessage: values['promo_message'] as String?,
      featureFlags: values['feature_flags'] is Map
          ? Map<String, dynamic>.from(values['feature_flags'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenance_mode': maintenanceMode,
      'minimum_app_version': minimumAppVersion,
      'force_update': forceUpdate,
      'promo_message': promoMessage,
      'feature_flags': featureFlags,
    };
  }
}
