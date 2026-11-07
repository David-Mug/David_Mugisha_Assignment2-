import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_status.dart';

/// One entry in an incident's audit trail, stored at
/// `incidents/{incidentId}/statusHistory/{id}`.
///
/// Kept in a sub-collection (not an array on the incident) so Security Rules
/// can make every entry append-only: staff can add history but nobody can
/// edit or delete it.
class StatusChange {
  const StatusChange({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.changedByName,
    required this.note,
    this.changedAt,
  });

  final String id;

  /// Null for the very first "Submitted" entry.
  final IncidentStatus? fromStatus;
  final IncidentStatus toStatus;
  final String changedBy;
  final String changedByName;
  final String note;
  final DateTime? changedAt;

  factory StatusChange.fromMap(String id, Map<String, dynamic> map) =>
      StatusChange(
        id: id,
        fromStatus: map['fromStatus'] == null
            ? null
            : IncidentStatus.fromName(map['fromStatus'] as String),
        toStatus: IncidentStatus.fromName(map['toStatus'] as String?),
        changedBy: map['changedBy'] as String? ?? '',
        changedByName: map['changedByName'] as String? ?? '',
        note: map['note'] as String? ?? '',
        changedAt: (map['changedAt'] as Timestamp?)?.toDate(),
      );
}
