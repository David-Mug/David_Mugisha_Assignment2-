import 'package:campus_incident/app.dart';
import 'package:campus_incident/data/providers.dart';
import 'package:campus_incident/data/storage_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

/// End-to-end widget tests: the real app, router and screens, running on
/// fake Firebase Auth + Firestore instead of the network.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  Future<void> pumpApp(WidgetTester tester, MockFirebaseAuth auth) async {
    // A tall phone-sized screen so long forms fit without scrolling issues.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firestoreProvider.overrideWithValue(db),
          storageRepositoryProvider.overrideWithValue(MockStorageRepository()),
        ],
        child: const CampusCareApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  MockFirebaseAuth signedInAs({
    required String uid,
    required String email,
    bool verified = true,
  }) => MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: uid, email: email, isEmailVerified: verified),
  );

  Future<void> addProfile(String uid, String name, String role) =>
      db.collection('users').doc(uid).set({
        'fullName': name,
        'email': '$uid@alustudent.com',
        'role': role,
        'createdAt': Timestamp.now(),
      });

  testWidgets('signed-out users land on Welcome and can open Login', (
    tester,
  ) async {
    await pumpApp(tester, MockFirebaseAuth());

    expect(find.text('Create an account'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('login shows validation errors before calling Firebase', (
    tester,
  ) async {
    await pumpApp(tester, MockFirebaseAuth());
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'me@gmail.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.textContaining('Use your ALU email'), findsOneWidget);
  });

  testWidgets('unverified users are held on Verify Email', (tester) async {
    await pumpApp(
      tester,
      signedInAs(uid: 'u1', email: 'u1@alustudent.com', verified: false),
    );
    expect(find.text('Verify your email'), findsOneWidget);
    expect(
      find.textContaining('u1@alustudent.com', findRichText: true),
      findsOneWidget,
    );

    // Remove the screen so its polling timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('verified students see Home with their name', (tester) async {
    await addProfile('u1', 'Amina Hassan', 'student');
    await pumpApp(tester, signedInAs(uid: 'u1', email: 'u1@alustudent.com'));

    expect(find.text('Hi, Amina 👋'), findsOneWidget);
    expect(find.text('Staff dashboard'), findsNothing);
  });

  testWidgets('staff see the staff shortcut on Home', (tester) async {
    await addProfile('s1', 'John Mugisha', 'staff');
    await pumpApp(tester, signedInAs(uid: 's1', email: 's1@alueducation.com'));

    expect(find.text('Hi, John 👋'), findsOneWidget);
    expect(find.text('Staff dashboard'), findsOneWidget);
  });

  testWidgets('a student can submit a report and lands on its details', (
    tester,
  ) async {
    await addProfile('u1', 'Amina Hassan', 'student');
    await pumpApp(tester, signedInAs(uid: 'u1', email: 'u1@alustudent.com'));

    await tester.tap(find.text('Report an incident'));
    await tester.pumpAndSettle();
    expect(find.text('Report an Incident'), findsOneWidget);

    // Submitting empty shows errors and saves nothing.
    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Choose a location'), findsOneWidget);
    expect((await db.collection('incidents').get()).docs, isEmpty);
    // Let the error SnackBar expire so it doesn't cover the Submit button.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Fill the form.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Broken tap in Block B');
    await tester.ensureVisible(find.text('Water'));
    await tester.tap(find.text('Water'));
    await tester.ensureVisible(find.text('Select a campus area'));
    await tester.tap(find.text('Select a campus area'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Student Residence').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), 'Room 204');
    await tester.enterText(
      fields.at(2),
      'Water has been leaking from the tap since this morning.',
    );

    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    final saved = (await db.collection('incidents').get()).docs;
    expect(saved, hasLength(1));
    expect(saved.single.data()['category'], 'water');
    expect(saved.single.data()['location'], 'residence');
    expect(saved.single.data()['reporterId'], 'u1');

    expect(find.text('Report details'), findsOneWidget);
    expect(find.text('Broken tap in Block B'), findsOneWidget);
    expect(find.text('Report submitted'), findsOneWidget); // timeline
    expect(find.text('Update status'), findsNothing); // students can't
  });
}
