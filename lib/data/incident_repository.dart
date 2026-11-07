import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/campus_location.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';
import '../models/status_change.dart';
import 'storage_repository.dart';

/// Creating, listing and updating incidents.
///
/// Data layout:
///   incidents/{id}                      — the report itself
///   incidents/{id}/statusHistory/{hid}  — append-only audit trail
class IncidentRepository {
  IncidentRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final StorageRepository _storage;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  CollectionReference<Map<String, dynamic>> _history(String incidentId) =>
      _incidents.doc(incidentId).collection('statusHistory');

  // ---------------------------------------------------------------- reading

  /// Every incident, newest first. Optionally only those with [status]
  /// (used by the staff dashboard filter).
  Stream<List<Incident>> watchAll({IncidentStatus? status}) {
    Query<Map<String, dynamic>> query = _incidents;
    if (status != null) query = query.where('status', isEqualTo: status.name);
    return _toIncidents(query.orderBy('createdAt', descending: true));
  }

  /// Incidents reported by one user, newest first ("My Reports").
  Stream<List<Incident>> watchByReporter(String uid) => _toIncidents(
    _incidents
        .where('reporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true),
  );

  /// A single incident, live. Emits null if it doesn't exist.
  Stream<Incident?> watchIncident(String id) => _incidents
      .doc(id)
      .snapshots()
      .map(
        (snap) => snap.exists ? Incident.fromMap(snap.id, snap.data()!) : null,
      );

  /// The status timeline for one incident, oldest first.
  Stream<List<StatusChange>> watchHistory(String incidentId) =>
      _history(incidentId)
          .orderBy('changedAt')
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => StatusChange.fromMap(d.id, d.data()))
                .toList(),
          );

  Stream<List<Incident>> _toIncidents(Query<Map<String, dynamic>> query) =>
      query.snapshots().map(
        (s) => s.docs.map((d) => Incident.fromMap(d.id, d.data())).toList(),
      );

  // ---------------------------------------------------------------- writing

  /// Saves a new report and returns its id.
  ///
  /// Steps:
  ///  1. Pick the document id up front, so the photo can be stored under it.
  ///  2. Upload the photo (if any) and get its URL.
  ///  3. In ONE batch, write the incident and its first "Submitted" history
  ///     entry — either both are saved or neither is.
  Future<String> createIncident({
    required AppUser reporter,
    required String title,
    required String description,
    required IncidentCategory category,
    required CampusLocation location,
    required String locationDetails,
    Uint8List? photoBytes,
  }) async {
    final docRef = _incidents.doc();

    String? photoUrl;
    if (photoBytes != null) {
      photoUrl = await _storage.uploadIncidentPhoto(
        uid: reporter.uid,
        incidentId: docRef.id,
        bytes: photoBytes,
      );
    }

    final incident = Incident(
      id: docRef.id,
      title: title,
      description: description,
      category: category,
      location: location,
      locationDetails: locationDetails,
      photoUrl: photoUrl,
      reporterId: reporter.uid,
      reporterName: reporter.fullName,
      status: IncidentStatus.submitted,
    );

    final batch = _db.batch()
      ..set(docRef, incident.toCreateMap())
      ..set(_history(docRef.id).doc(), {
        'fromStatus': null,
        'toStatus': IncidentStatus.submitted.name,
        'changedBy': reporter.uid,
        'changedByName': reporter.fullName,
        'note': 'Report submitted',
        'changedAt': FieldValue.serverTimestamp(),
      });

    try {
      await batch.commit();
      return docRef.id;
    } catch (e) {
      if (photoUrl != null) {
        await _storage.deleteIncidentPhoto(
          uid: reporter.uid,
          incidentId: docRef.id,
        );
      }
      throw AppException.from(e);
    }
  }

  /// Staff only: moves an incident to [next] and records who did it and why.
  ///
  /// Runs in a transaction that re-reads the current status first. If two
  /// staff members update the same report at the same moment, the second one
  /// sees the first one's change instead of silently overwriting it.
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus next,
    required AppUser staff,
    String note = '',
  }) async {
    if (!staff.isStaff) {
      throw const AppException('Only staff can change the status of a report.');
    }
    final docRef = _incidents.doc(incidentId);

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) {
          throw const AppException('That report no longer exists.');
        }

        final current = IncidentStatus.fromName(
          snap.data()!['status'] as String?,
        );
        if (!current.canTransitionTo(next)) {
          throw AppException(
            'A report that is ${current.label} cannot be moved to ${next.label}.',
          );
        }

        tx.update(docRef, statusUpdateFields(next));
        tx.set(_history(incidentId).doc(), {
          'fromStatus': current.name,
          'toStatus': next.name,
          'changedBy': staff.uid,
          'changedByName': staff.fullName,
          'note': note.trim(),
          'changedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// The fields written to the incident when its status changes.
  ///
  /// Timestamps always describe the *current* journey, so they can drive the
  /// timeline on the detail screen:
  ///  - In Progress → stamp `inProgressAt`, clear `resolvedAt` (re-opened)
  ///  - Resolved    → stamp `resolvedAt`, keep `inProgressAt` as it was
  ///  - Submitted   → clear both (moved back to the start)
  static Map<String, dynamic> statusUpdateFields(IncidentStatus next) {
    final now = FieldValue.serverTimestamp();
    return {
      'status': next.name,
      'updatedAt': now,
      ...switch (next) {
        IncidentStatus.inProgress => {'inProgressAt': now, 'resolvedAt': null},
        IncidentStatus.resolved => {'resolvedAt': now},
        IncidentStatus.submitted => {'inProgressAt': null, 'resolvedAt': null},
      },
    };
  }
}
