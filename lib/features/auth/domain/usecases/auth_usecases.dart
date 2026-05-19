import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Returns the currently authenticated user, or null.
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<(UserEntity?, Failure?)> call() => _repository.getCurrentUser();

  Stream<UserEntity?> get authStateChanges => _repository.authStateChanges;
}

/// Signs in with email and password.
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<(UserEntity?, Failure?)> call({
    required String email,
    required String password,
  }) =>
      _repository.loginWithEmail(email: email, password: password);
}

/// Creates a new account.
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<(UserEntity?, Failure?)> call({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _repository.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
}

/// Signs in via Google OAuth.
class GoogleSignInUseCase {
  final AuthRepository _repository;

  const GoogleSignInUseCase(this._repository);

  Future<(UserEntity?, Failure?)> call() => _repository.signInWithGoogle();
}

/// Logs out the current user.
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Failure?> call() => _repository.logout();
}
