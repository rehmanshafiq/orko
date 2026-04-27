import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/remote_config/domain/entities/remote_config_entity.dart';

/// Abstract remote config repository contract.
abstract class RemoteConfigRepository {
  /// Fetches and activates remote config values.
  Future<Either<Failure, RemoteConfigEntity>> fetchConfig();

  /// Gets a specific string value by key.
  String getString(String key, {String defaultValue = ''});

  /// Gets a specific bool value by key.
  bool getBool(String key, {bool defaultValue = false});

  /// Gets a specific int value by key.
  int getInt(String key, {int defaultValue = 0});
}
