/// Exception hierarchy for the data layer.
/// 
/// These are thrown by data sources and caught in repository implementations,
/// where they are mapped to [Failure] objects for the domain layer.
sealed class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// No connectivity detected.
final class NetworkException extends AppException {
  const NetworkException({String message = 'No internet connection.'})
      : super(message);
}

/// Firebase / remote API returned an error status.
final class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, {this.statusCode, super.stackTrace});
}

/// Hive local DB read/write failure.
final class CacheException extends AppException {
  const CacheException({String message = 'Cache operation failed.'})
      : super(message);
}

/// Firebase Auth specific errors.
final class AuthException extends AppException {
  const AuthException(super.message);
}

/// Gemini API or AI processing error.
final class AiException extends AppException {
  const AiException({String message = 'AI request failed.'}) : super(message);
}
