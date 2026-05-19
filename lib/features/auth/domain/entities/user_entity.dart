import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated user.
///
/// This is pure Dart — no Firebase dependencies.
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  /// Returns the user's display name, falling back to the email prefix.
  String get name => displayName ?? email.split('@').first;

  /// True if the user has a profile photo.
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, createdAt];
}
