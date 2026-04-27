import 'package:orko_hubco/core/constants/api_constants.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';

/// Concrete implementation of [AuthRemoteDataSource] using Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  const AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        // Postman echo reflects our request data inside JSON mapping
        final echoedEmail = response.data['json']?['email']?.toString() ?? email;
        return UserModel(
          id: '1',
          email: echoedEmail,
          name: 'Demo User',
          avatarUrl: 'https://i.pravatar.cc/150?u=1',
        );
      }

      throw ServerException(
        message: response.data?['message'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        // Postman echo reflects our request data
        final echoedEmail = response.data['json']?['email']?.toString() ?? email;
        final echoedName = response.data['json']?['name']?.toString() ?? name;
        return UserModel(
          id: '1',
          email: echoedEmail,
          name: echoedName,
          avatarUrl: 'https://i.pravatar.cc/150?u=1',
        );
      }

      throw ServerException(
        message: response.data?['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.logout);
    } catch (e) {
      throw ServerException(message: e.toString(), originalError: e);
    }
  }
}
