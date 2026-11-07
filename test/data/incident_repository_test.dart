import 'dart:typed_data';

import 'package:campus_incident/core/errors/app_exception.dart';
import 'package:campus_incident/data/incident_repository.dart';
import 'package:campus_incident/data/storage_repository.dart';
import 'package:campus_incident/models/app_user.dart';
import 'package:campus_incident/models/campus_location.dart';
import 'package:campus_incident/models/incident.dart';
import 'package:campus_incident/models/incident_category.dart';
import 'package:campus_incident/models/incident_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

const student = AppUser(
  uid: 'student-1',
  fullName: 'Amina Hassan',
  email: 'amina@alustudent.com',
  role: UserRole.student,
);

const staff = AppUser(
  uid: 'staff-1',
  fullName: 'John Mugisha',
  email: 'john@alueducation.com',
  role: UserRole.staff,
);

void main() {
  late FakeFirebaseFirestore db;
  late MockStorageRepository storage;
  late IncidentRepository repo;

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    db = FakeFirebaseFirestore();
    storage = MockStorageRepository();
    repo = IncidentRepository(db, storage);
  });

  Future<String> createSample({Uint8List? photo, AppUser reporter = student}) =>
      repo.createIncident(
        reporter: reporter,
        title: ' Water shortage ',
        description: 'No water in Block B since morning',
        category: IncidentCategory.water,
        location: CampusLocation.residence,
        locationDetails: 'Block B',
        photoBytes: photo,
      );

  group('createIncident', () {
    test(
      'saves the incident as Submitted with an initial history entry',
      () async {
        final id = await createSample();

        final doc = await db.collection('incidents').doc(id).get();
        expect(doc.data()!['title'], 'Water shortage');
        expect(doc.data()!['status'], 'submitted');
        expect(doc.data()!['reporterId'], student.uid);
        expect(doc.data()!['reporterName'], student.fullName);
        expect(doc.data()!['photoUrl'], isNull);
        expect(doc.data()!['createdAt'], isA<Timestamp>());

        final history = await db
            .collection('incidents/$id/statusHistory')
            .get();
        expect(history.docs, hasLength(1));
        expect(history.docs.single.data()['fromStatus'], isNull);
        expect(history.docs.single.data()['toStatus'], 'submitted');

        verifyNever(
          () => storage.uploadIncidentPhoto(
            uid: any(named: 'uid'),
            incidentId: any(named: 'incidentId'),
            bytes: any(named: 'bytes'),
          ),
        );
      },
    );

    test(
      'uploads the photo under the new incident id and stores its URL',
      () async {
        when(
          () => storage.uploadIncidentPhoto(
            uid: any(named: 'uid'),
            incidentId: any(named: 'incidentId'),
            bytes: any(named: 'bytes'),
          ),
        ).thenAnswer((_) async => 'https://example.com/photo.jpg');

        final id = await createSample(photo: Uint8List.fromList([1, 2, 3]));

        verify(
          () => storage.uploadIncidentPhoto(
            uid: student.uid,
            incidentId: id,
            bytes: any(named: 'bytes'),
          ),
        ).called(1);
        final doc = await db.collection('incidents').doc(id).get();
        expect(doc.data()!['photoUrl'], 'https://example.com/photo.jpg');
      },
    );
  });

  group('watch queries', () {
    test('watchIncident maps the document, or null when missing', () async {
      final id = await createSample();
      final incident = await repo.watchIncident(id).first;
      expect(incident!.title, 'Water shortage');
      expect(incident.category, IncidentCategory.water);
      expect(await repo.watchIncident('missing').first, isNull);
    });

    test('watchByReporter only returns that user\'s reports', () async {
      await createSample();
      await createSample(
        reporter: const AppUser(
          uid: 'other',
          fullName: 'Other Student',
          email: 'o@alustudent.com',
          role: UserRole.student,
        ),
      );

      final mine = await repo.watchByReporter(student.uid).first;
      expect(mine, hasLength(1));
      expect(mine.single.reporterId, student.uid);
    });

    test('watchAll filters by status', () async {
      final a = await createSample();
      await createSample();
      await repo.updateStatus(
        incidentId: a,
        next: IncidentStatus.inProgress,
        staff: staff,
      );

      expect(await repo.watchAll().first, hasLength(2));
      final inProgress = await repo
          .watchAll(status: IncidentStatus.inProgress)
          .first;
      expect(inProgress.map((i) => i.id), [a]);
    });
  });

  group('updateStatus', () {
    test('moves the status, stamps the time and records history', () async {
      final id = await createSample();

      await repo.updateStatus(
        incidentId: id,
        next: IncidentStatus.inProgress,
        staff: staff,
        note: ' Plumber assigned ',
      );

      // Read directly: fake_cloud_firestore's single-doc `snapshots().first`
      // can replay a stale value after a transaction (a quirk of the fake).
      final snap = await db.collection('incidents').doc(id).get();
      final incident = Incident.fromMap(id, snap.data()!);
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.inProgressAt, isNotNull);
      expect(incident.resolvedAt, isNull);

      final history = await repo.watchHistory(id).first;
      expect(history, hasLength(2));
      final latest = history.firstWhere((h) => h.fromStatus != null);
      expect(latest.fromStatus, IncidentStatus.submitted);
      expect(latest.toStatus, IncidentStatus.inProgress);
      expect(latest.changedBy, staff.uid);
      expect(latest.note, 'Plumber assigned');
    });

    test('students cannot change status', () async {
      final id = await createSample();
      await expectLater(
        repo.updateStatus(
          incidentId: id,
          next: IncidentStatus.resolved,
          staff: student,
        ),
        throwsA(isA<AppException>()),
      );
      final snap = await db.collection('incidents').doc(id).get();
      expect(snap.data()!['status'], 'submitted');
    });

    test('invalid transitions are rejected and nothing is written', () async {
      final id = await createSample();
      // Submitted → Submitted is not a transition.
      await expectLater(
        repo.updateStatus(
          incidentId: id,
          next: IncidentStatus.submitted,
          staff: staff,
        ),
        throwsA(isA<AppException>()),
      );
      expect(await repo.watchHistory(id).first, hasLength(1));
    });

    test('missing incident gives a friendly error', () async {
      await expectLater(
        repo.updateStatus(
          incidentId: 'nope',
          next: IncidentStatus.resolved,
          staff: staff,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'That report no longer exists.',
          ),
        ),
      );
    });
  });

  group('statusUpdateFields', () {
    test('re-opening clears resolvedAt', () {
      final f = IncidentRepository.statusUpdateFields(
        IncidentStatus.inProgress,
      );
      expect(f['status'], 'inProgress');
      expect(f.containsKey('inProgressAt'), isTrue);
      expect(f['resolvedAt'], isNull);
    });

    test('resolving keeps inProgressAt untouched', () {
      final f = IncidentRepository.statusUpdateFields(IncidentStatus.resolved);
      expect(f.containsKey('resolvedAt'), isTrue);
      expect(f.containsKey('inProgressAt'), isFalse);
    });

    test('moving back to submitted clears both timestamps', () {
      final f = IncidentRepository.statusUpdateFields(IncidentStatus.submitted);
      expect(f['inProgressAt'], isNull);
      expect(f['resolvedAt'], isNull);
    });
  });
}
