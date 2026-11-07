import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';

/// Reads and updates profiles in the `users` collection.
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  /// Live profile. Emits null if the document doesn't exist (yet).
  Stream<AppUser?> watchUser(String uid) => _doc(uid).snapshots().map(
    (snap) => snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null,
  );

  /// Users may only change their name and photo; `role` and `email` are
  /// locked by Firestore rules.
  Future<void> updateProfile(
    String uid, {
    String? fullName,
    String? photoUrl,
  }) async {
    // `'key': ?value` only adds the entry when value is non-null.
    final changes = <String, dynamic>{
      'fullName': ?fullName?.trim(),
      'photoUrl': ?photoUrl,
    };
    if (changes.isEmpty) return;
    try {
      await _doc(uid)
          .update({...changes, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
