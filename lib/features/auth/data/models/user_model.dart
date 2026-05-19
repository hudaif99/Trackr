import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Data model for the user — handles Firestore serialisation.
///
/// Only lives in the data layer. [UserEntity] is what the domain/presentation see.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoUrl,
    required super.createdAt,
  });

  factory UserModel.fromFirebaseUser({
    required String uid,
    required String? email,
    String? displayName,
    String? photoUrl,
  }) =>
      UserModel(
        uid: uid,
        email: email ?? '',
        displayName: displayName,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

  factory UserModel.fromFirestore(Map<String, dynamic> data) => UserModel(
        uid: data['uid'] as String,
        email: data['email'] as String,
        displayName: data['displayName'] as String?,
        photoUrl: data['photoUrl'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
