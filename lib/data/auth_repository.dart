import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/validators.dart';
import '../models/app_user.dart';

/// Everything to do with signing in and out.
///
/// Firebase Auth stores only the email and password. On registration we also
/// create the user's profile document at `users/{uid}` (name and role), which
/// the rest of the app reads.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Emits whenever the user signs in, signs out, or their profile
  /// (e.g. `emailVerified` after [reloadUser]) changes.
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// Creates the account, writes the profile and sends the verification email.
  ///
  /// New users are always `student`; Firestore rules reject any other role,
  /// so a user can't make themselves staff.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    // Checked here as well as in the form, so the rule holds even if a
    // future screen forgets to validate.
    if (!Validators.isAluEmail(normalizedEmail)) {
      throw const AppException('Only ALU email addresses can register.');
    }

    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } catch (e) {
      throw AppException.from(e);
    }

    final user = credential.user!;
    try {
      await _db.collection('users').doc(user.uid).set({
        'fullName': fullName.trim(),
        'email': normalizedEmail,
        'role': UserRole.student.name,
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await user.updateDisplayName(fullName.trim());
      await user.sendEmailVerification();
    } catch (e) {
      // Don't leave a half-created account (auth user with no profile)
      // behind: remove it so the user can simply try registering again.
      await user.delete().catchError((_) {});
      throw AppException.from(e);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Firebase does not reveal whether the email exists; it simply sends the
  /// email if it does. The UI should show the same message either way.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Re-fetches the user after they click the link in the verification email.
  ///
  /// Returns true once verified.
  ///
  /// Security Rules read `email_verified` from the ID *token*, not from the
  /// user object, so we fetch a fresh token FIRST. Then `reload()` updates
  /// `emailVerified` — which is what moves the user into the app — and by
  /// that point Firestore will already accept their requests.
  Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.getIdTokenResult(true);
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
