import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Data source for all Firebase Auth operations.
///
/// Throws [AuthException] or [ServerException] — the repository impl
/// is responsible for catching and converting to [Failure].
class FirebaseAuthDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  const FirebaseAuthDataSource(this._auth, this._firestore, this._googleSignIn);

  // ── Current user ──────────────────────────────────────────────────────────
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user == null
            ? null
            : UserModel.fromFirebaseUser(
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                photoUrl: user.photoURL,
              ),
      );

  // ── Email auth ─────────────────────────────────────────────────────────────
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _userFromCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (e) {
      throw AuthException('Login failed. Please try again.');
    }
  }

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null) {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
      }
      final model = _userFromCredential(credential, displayName: displayName);
      await _saveUserToFirestore(model);
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (e) {
      throw AuthException('Registration failed. Please try again.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final model = _userFromCredential(userCredential);
      await _saveUserToFirestore(model);
      return model;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (e) {
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (e) {
      throw AuthException('Failed to send reset link. Please try again.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  UserModel _userFromCredential(
    UserCredential credential, {
    String? displayName,
  }) {
    final user = credential.user!;
    return UserModel.fromFirebaseUser(
      uid: user.uid,
      email: user.email,
      displayName: displayName ?? user.displayName,
      photoUrl: user.photoURL,
    );
  }

  Future<void> _saveUserToFirestore(UserModel model) async {
    final doc = _firestore
        .collection(AppConstants.usersCollection)
        .doc(model.uid);
    final snap = await doc.get();
    // Don't overwrite existing users — only write on first sign-up.
    if (!snap.exists) {
      await doc.set(model.toFirestore());
    }
  }

  String _mapAuthError(String code) => switch (code) {
        'invalid-credential' => 'Invalid email or password.',
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'email-already-in-use' => 'An account already exists for this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Password must be at least 6 characters.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'Network error. Check your connection.',
        _ => 'Authentication failed. Please try again.',
      };
}
