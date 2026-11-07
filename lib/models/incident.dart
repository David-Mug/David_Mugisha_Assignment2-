import 'package:cloud_firestore/cloud_firestore.dart';

import 'campus_location.dart';
import 'incident_category.dart';
import 'incident_status.dart';

/// A reported campus incident, stored at `incidents/{id}`.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.locationDetails,
    required this.reporterId,
    required this.reporterName,
    required this.status,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.inProgressAt,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final CampusLocation location;
  final String locationDetails;
  final String? photoUrl;
  final String reporterId;
  final String reporterName;
  final IncidentStatus status;

  /// May be null for a split second after creation, until the server
  /// timestamp arrives — UI code must handle that.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? inProgressAt;
  final DateTime? resolvedAt;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Human-readable location, e.g. "Student Residence · Block B, Room 204".
  String get locationLabel => locationDetails.isEmpty
      ? location.label
      : '${location.label} · $locationDetails';

  /// When the incident reached [s], used by the status timeline.
  DateTime? reachedAt(IncidentStatus s) => switch (s) {
    IncidentStatus.submitted => createdAt,
    IncidentStatus.inProgress => inProgressAt,
    IncidentStatus.resolved => resolvedAt,
  };

  factory Incident.fromMap(String id, Map<String, dynamic> map) => Incident(
    id: id,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    category: IncidentCategory.fromName(map['category'] as String?),
    location: CampusLocation.fromName(map['location'] as String?),
    locationDetails: map['locationDetails'] as String? ?? '',
    photoUrl: map['photoUrl'] as String?,
    reporterId: map['reporterId'] as String? ?? '',
    reporterName: map['reporterName'] as String? ?? '',
    status: IncidentStatus.fromName(map['status'] as String?),
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
    inProgressAt: _date(map['inProgressAt']),
    resolvedAt: _date(map['resolvedAt']),
  );

  /// Fields written when a student first creates the report.
  ///
  /// `status`, timestamps and reporter fields are set here once; Firestore
  /// rules stop students from changing them afterwards.
  Map<String, dynamic> toCreateMap() => {
    'title': title.trim(),
    'description': description.trim(),
    'category': category.name,
    'location': location.name,
    'locationDetails': locationDetails.trim(),
    'photoUrl': photoUrl,
    'reporterId': reporterId,
    'reporterName': reporterName,
    'status': IncidentStatus.submitted.name,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'inProgressAt': null,
    'resolvedAt': null,
  };

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
