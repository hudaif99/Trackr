import 'package:equatable/equatable.dart';

/// Base class for all domain-layer failures.
/// 
/// Use [Either<Failure, T>] (or a simple sealed class approach) in use cases.
/// Keeps error handling uniform across the entire app.
sealed class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.stackTrace});

  @override
  List<Object?> get props => [message];
}

/// Thrown when there is no internet connection.
final class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'No internet connection.'})
      : super(message);
}

/// Thrown on Firebase or remote API errors.
final class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode, super.stackTrace});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Thrown on local Hive cache read/write failures.
final class CacheFailure extends Failure {
  const CacheFailure({String message = 'Local cache error.'}) : super(message);
}

/// Thrown on Firebase Authentication failures.
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Thrown when Gemini AI categorization fails.
final class AiFailure extends Failure {
  const AiFailure({String message = 'AI categorization failed.'})
      : super(message);
}

/// Thrown on unexpected errors not covered by the above.
final class UnknownFailure extends Failure {
  const UnknownFailure({
    String message = 'An unexpected error occurred.',
    super.stackTrace,
  }) : super(message);
}
