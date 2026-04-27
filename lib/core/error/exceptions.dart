/// Base exception class for all app-specific exceptions.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'AppException(message: $message, statusCode: $statusCode)';
}

/// Thrown when a server request fails.
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.originalError,
  });
}

/// Thrown when there's no cached data available.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.originalError,
  });
}

/// Thrown when the device has no internet connection.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.originalError,
  });
}

/// Thrown when authentication fails (token expired, etc).
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized access',
    super.statusCode = 401,
    super.originalError,
  });
}
