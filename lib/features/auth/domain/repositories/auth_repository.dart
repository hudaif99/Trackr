import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract for authentication operations.
///
/// The data layer provides [AuthRepositoryImpl]; the domain layer
/// only knows about this abstract interface.
abstract class AuthRepository {
  /// Returns the currently signed-in user, or null if not authenticated.
  Future<(UserEntity?, Failure?)> getCurrentUser();

  /// Signs in with email and password.
  Future<(UserEntity?, Failure?)> loginWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  Future<(UserEntity?, Failure?)> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs in with Google OAuth.
  Future<(UserEntity?, Failure?)> signInWithGoogle();

  /// Signs out the current user.
  Future<Failure?> logout();

  /// Stream of auth state changes — emits the user or null.
  Stream<UserEntity?> get authStateChanges;
}
