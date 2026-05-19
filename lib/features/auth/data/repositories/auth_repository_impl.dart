import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Concrete implementation of [AuthRepository].
///
/// Catches [AppException]s from the data source and converts them to
/// [Failure]s for the domain layer. The domain never sees Firebase types.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<(UserEntity?, Failure?)> getCurrentUser() async {
    try {
      final user = _dataSource.currentUser;
      return (user, null);
    } catch (e) {
      return (null, UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<(UserEntity?, Failure?)> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.loginWithEmail(
        email: email,
        password: password,
      );
      return (user, null);
    } on AuthException catch (e) {
      return (null, AuthFailure(e.message));
    } on NetworkException {
      return (null, const NetworkFailure());
    } catch (e) {
      return (null, UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<(UserEntity?, Failure?)> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _dataSource.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      return (user, null);
    } on AuthException catch (e) {
      return (null, AuthFailure(e.message));
    } on NetworkException {
      return (null, const NetworkFailure());
    } catch (e) {
      return (null, UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<(UserEntity?, Failure?)> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return (user, null);
    } on AuthException catch (e) {
      return (null, AuthFailure(e.message));
    } on NetworkException {
      return (null, const NetworkFailure());
    } catch (e) {
      return (null, UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Failure?> logout() async {
    try {
      await _dataSource.logout();
      return null;
    } catch (e) {
      return UnknownFailure(message: e.toString());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;
}
