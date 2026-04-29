import 'package:dio/dio.dart';
import 'package:orko_hubco/core/constants/api_constants.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/map/data/models/hubco_location_model.dart';

abstract class MapRemoteDataSource {
  Future<List<HubcoLocationModel>> getHubcoLocations();
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final ApiClient apiClient;

  const MapRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<HubcoLocationModel>> getHubcoLocations() async {
    try {
      final response = await apiClient.get(
        ApiConstants.hubcoLocations,
        options: Options(
          headers: {
            'Request-Origin': 'portal',
          },
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is List) {
          return body
              .whereType<Map<String, dynamic>>()
              .map(HubcoLocationModel.fromJson)
              .toList();
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to load hubco locations',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }
}
