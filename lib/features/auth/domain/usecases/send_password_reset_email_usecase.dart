import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for sending a password reset email to the given address.
class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;

  const SendPasswordResetEmailUseCase(this._repository);

  Future<Failure?> call({required String email}) {
    return _repository.sendPasswordResetEmail(email: email);
  }
}
