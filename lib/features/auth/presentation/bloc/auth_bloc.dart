import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_event.dart';

export 'auth_event.dart';

/// Manages authentication state for the entire app.
///
/// Exposed via [MultiBlocProvider] at the root so any widget can read
/// the current user. Navigation redirects are handled by [AppRouter]
/// which listens to auth state changes.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUserUseCase _getCurrentUser;
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final GoogleSignInUseCase _googleSignIn;
  final LogoutUseCase _logout;
  final SendPasswordResetEmailUseCase _sendPasswordResetEmail;

  AuthBloc({
    required GetCurrentUserUseCase getCurrentUser,
    required LoginUseCase login,
    required RegisterUseCase register,
    required GoogleSignInUseCase googleSignIn,
    required LogoutUseCase logout,
    required SendPasswordResetEmailUseCase sendPasswordResetEmail,
  })  : _getCurrentUser = getCurrentUser,
        _login = login,
        _register = register,
        _googleSignIn = googleSignIn,
        _logout = logout,
        _sendPasswordResetEmail = sendPasswordResetEmail,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthPasswordResetRequested>(_onPasswordReset);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final (user, failure) = await _getCurrentUser();
    if (failure != null) {
      emit(const AuthUnauthenticated());
      return;
    }
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final (user, failure) = await _login(
      email: event.email,
      password: event.password,
    );
    if (failure != null) {
      emit(AuthError(failure.message));
      return;
    }
    emit(AuthAuthenticated(user!));
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final (user, failure) = await _register(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    if (failure != null) {
      emit(AuthError(failure.message));
      return;
    }
    emit(AuthAuthenticated(user!));
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final (user, failure) = await _googleSignIn();
    if (failure != null) {
      emit(AuthError(failure.message));
      return;
    }
    emit(AuthAuthenticated(user!));
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final failure = await _sendPasswordResetEmail(email: event.email);
    if (failure != null) {
      emit(AuthError(failure.message));
      return;
    }
    emit(const AuthPasswordResetSuccess());
    // Since we don't want to leave the state as AuthPasswordResetSuccess indefinitely,
    // we revert back to unauthenticated (since they are resetting their password, they are likely not logged in)
    emit(const AuthUnauthenticated());
  }
}
