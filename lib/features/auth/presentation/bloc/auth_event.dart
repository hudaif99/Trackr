import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

// ── Events ─────────────────────────────────────────────────────────────────

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if a user is already signed in on startup.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Login with email and password.
final class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Register a new account.
final class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign in via Google.
final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Logout the current user.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Request a password reset email.
final class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

// ── States ─────────────────────────────────────────────────────────────────

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — auth status not yet determined.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Async operation in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
final class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// No user is signed in.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Password reset email sent successfully.
final class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}
