import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/features/map/data/models/hubco_location_model.dart';

abstract class MapLocalDataSource {
  Future<List<HubcoLocationModel>> getHubcoLocations();
}

class MapLocalDataSourceImpl implements MapLocalDataSource {
  static const String _assetPath = 'assets/data/hubco_locations.json';

  const MapLocalDataSourceImpl();

  @override
  Future<List<HubcoLocationModel>> getHubcoLocations() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(raw);

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(HubcoLocationModel.fromJson)
            .toList();
      }

      throw const ServerException(
        message: 'Invalid hubco locations asset format',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }
}
