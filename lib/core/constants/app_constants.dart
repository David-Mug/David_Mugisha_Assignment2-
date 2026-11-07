/// App-wide configuration values.
///
/// The ALU email domains live here so that the registration validator, the
/// UI hints and the documentation all agree. Firestore Security Rules repeat
/// the same domains server-side (they cannot import Dart code), so if a domain
/// ever changes, update `firestore.rules` as well.
abstract final class AppConstants {
  static const appName = 'CampusCare';

  /// Domain used by ALU students, e.g. `name@alustudent.com`.
  static const studentEmailDomain = 'alustudent.com';

  /// Domain used by ALU staff, e.g. `name@alueducation.com`.
  /// A staff-domain email does NOT grant staff rights by itself — the `staff`
  /// role is assigned by an administrator in the Firebase Console.
  static const staffEmailDomain = 'alueducation.com';

  static const allowedEmailDomains = [studentEmailDomain, staffEmailDomain];

  // Input limits (mirrored in Firestore rules).
  static const titleMaxLength = 80;
  static const descriptionMaxLength = 1000;
  static const locationDetailsMaxLength = 100;
  static const statusNoteMaxLength = 300;
  static const nameMaxLength = 60;
  static const minPasswordLength = 8;

  /// Maximum photo size accepted (mirrored in Storage rules).
  static const maxPhotoBytes = 5 * 1024 * 1024;
}
