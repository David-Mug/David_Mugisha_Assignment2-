import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';

/// Uploads photos to Firebase Storage and returns their download URLs.
///
/// Takes raw bytes rather than a file path, so the same code works on
/// Android, iOS and web (web has no file system).
///
/// Folder layout (matched by `storage.rules`):
///   incident_photos/{uid}/{incidentId}.jpg
///   profile_photos/{uid}/avatar.jpg
class StorageRepository {
  StorageRepository(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) => _upload('incident_photos/$uid/$incidentId.jpg', bytes, contentType);

  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) => _upload('profile_photos/$uid/avatar.jpg', bytes, contentType);

  /// Best-effort clean-up, used when a report fails to save after its photo
  /// was already uploaded. Errors are ignored: an orphaned file is harmless.
  Future<void> deleteIncidentPhoto({
    required String uid,
    required String incidentId,
  }) async {
    try {
      await _storage.ref('incident_photos/$uid/$incidentId.jpg').delete();
    } catch (_) {}
  }

  Future<String> _upload(
    String path,
    Uint8List bytes,
    String contentType,
  ) async {
    // Checked here for a fast, friendly error; storage.rules enforce it too.
    if (bytes.lengthInBytes > AppConstants.maxPhotoBytes) {
      throw const AppException(
        'Photo is too large. Please choose one under 5 MB.',
      );
    }
    try {
      final ref = _storage.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
