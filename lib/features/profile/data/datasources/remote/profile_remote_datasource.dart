import 'package:orko_hubco/core/constants/api_constants.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/profile/data/models/profile_model.dart';

/// Remote data source for profile operations.
abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  const ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final response = await apiClient.get(ApiConstants.profile);
      if (response.statusCode == 200 && response.data != null) {
        return ProfileModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(message: 'Failed to load profile', statusCode: response.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put(ApiConstants.updateProfile, data: data);
      if (response.statusCode == 200 && response.data != null) {
        return ProfileModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(message: 'Failed to update profile', statusCode: response.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }
}
