import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  staff;

  static UserRole fromName(String? value) =>
      value == 'staff' ? UserRole.staff : UserRole.student;
}

/// A CampusCare user profile, stored at `users/{uid}`.
///
/// Firebase Auth only knows the email and password; everything app-specific
/// (name, role) lives in this Firestore document.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isStaff => role == UserRole.staff;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// Up to two initials for the avatar placeholder, e.g. "Amina Hassan" → "AH".
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    fullName: map['fullName'] as String? ?? '',
    email: map['email'] as String? ?? '',
    role: UserRole.fromName(map['role'] as String?),
    photoUrl: map['photoUrl'] as String?,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );
}
