import 'package:campus_incident/models/campus_location.dart';
import 'package:campus_incident/models/incident.dart';
import 'package:campus_incident/models/incident_category.dart';
import 'package:campus_incident/models/incident_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Incident serialization', () {
    final created = DateTime(2026, 10, 15, 10, 24);

    test('fromMap reads every field', () {
      final incident = Incident.fromMap('abc', {
        'title': 'Water shortage',
        'description': 'No water since morning',
        'category': 'water',
        'location': 'residence',
        'locationDetails': 'Block B',
        'photoUrl': 'https://example.com/p.jpg',
        'reporterId': 'u1',
        'reporterName': 'Amina',
        'status': 'inProgress',
        'createdAt': Timestamp.fromDate(created),
      });

      expect(incident.id, 'abc');
      expect(incident.category, IncidentCategory.water);
      expect(incident.location, CampusLocation.residence);
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.createdAt, created);
      expect(incident.hasPhoto, isTrue);
      expect(incident.locationLabel, 'Student Residence · Block B');
      expect(incident.reachedAt(IncidentStatus.submitted), created);
      expect(incident.reachedAt(IncidentStatus.resolved), isNull);
    });

    test('fromMap tolerates missing or unknown values', () {
      final incident = Incident.fromMap('x', {
        'category': 'aliens',
        'status': '??',
      });
      expect(incident.category, IncidentCategory.other);
      expect(incident.status, IncidentStatus.submitted);
      expect(incident.createdAt, isNull);
      expect(incident.hasPhoto, isFalse);
    });

    test('toCreateMap always starts as submitted and trims text', () {
      const draft = Incident(
        id: '',
        title: '  Broken projector ',
        description: ' Not turning on ',
        category: IncidentCategory.facilities,
        location: CampusLocation.classroom,
        locationDetails: '',
        reporterId: 'u1',
        reporterName: 'Amina',
        status: IncidentStatus.resolved, // ignored on purpose
      );
      final map = draft.toCreateMap();
      expect(map['status'], 'submitted');
      expect(map['title'], 'Broken projector');
      expect(map['description'], 'Not turning on');
      expect(map['category'], 'facilities');
      expect(map['createdAt'], isA<FieldValue>());
    });
  });

  group('IncidentStatus transitions', () {
    test('allowed moves', () {
      expect(
        IncidentStatus.submitted.canTransitionTo(IncidentStatus.inProgress),
        isTrue,
      );
      expect(
        IncidentStatus.inProgress.canTransitionTo(IncidentStatus.resolved),
        isTrue,
      );
      expect(
        IncidentStatus.resolved.canTransitionTo(IncidentStatus.inProgress),
        isTrue,
      );
    });

    test('blocked moves', () {
      expect(
        IncidentStatus.submitted.canTransitionTo(IncidentStatus.submitted),
        isFalse,
      );
      expect(
        IncidentStatus.resolved.canTransitionTo(IncidentStatus.submitted),
        isFalse,
      );
    });
  });
}
