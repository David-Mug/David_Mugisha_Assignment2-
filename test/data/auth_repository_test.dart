import 'package:campus_incident/core/errors/app_exception.dart';
import 'package:campus_incident/data/auth_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;
  late AuthRepository repo;

  setUp(() {
    auth = MockFirebaseAuth(verifyEmailAutomatically: false);
    db = FakeFirebaseFirestore();
    repo = AuthRepository(auth, db);
  });

  group('register', () {
    test('creates the auth user and a student profile', () async {
      await repo.register(
        fullName: '  Amina Hassan ',
        email: 'A.Hassan@ALUstudent.com',
        password: 'secret123',
      );

      final user = auth.currentUser!;
      expect(user.email, 'a.hassan@alustudent.com');
      expect(user.displayName, 'Amina Hassan');

      final profile = await db.collection('users').doc(user.uid).get();
      expect(profile.exists, isTrue);
      expect(profile.data()!['fullName'], 'Amina Hassan');
      expect(profile.data()!['email'], 'a.hassan@alustudent.com');
      expect(profile.data()!['role'], 'student');
    });

    test('staff-domain emails still register as student', () async {
      await repo.register(
        fullName: 'John Staff',
        email: 'john@alueducation.com',
        password: 'secret123',
      );
      final profile = await db
          .collection('users')
          .doc(auth.currentUser!.uid)
          .get();
      expect(profile.data()!['role'], 'student');
    });

    test('rejects non-ALU emails before contacting Firebase', () async {
      await expectLater(
        repo.register(
          fullName: 'Bob Smith',
          email: 'bob@gmail.com',
          password: 'secret123',
        ),
        throwsA(isA<AppException>()),
      );
      expect(auth.currentUser, isNull);
      expect((await db.collection('users').get()).docs, isEmpty);
    });
  });

  test('signIn then signOut updates currentUser', () async {
    final signedOut = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'amina@alustudent.com'),
    );
    final r = AuthRepository(signedOut, db);

    await r.signIn(email: 'amina@alustudent.com', password: 'secret123');
    expect(r.currentUser?.uid, 'u1');

    await r.signOut();
    expect(r.currentUser, isNull);
  });

  test('reloadUser reports verification state', () async {
    final verified = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'u1',
        email: 'a@alustudent.com',
        isEmailVerified: true,
      ),
    );
    expect(await AuthRepository(verified, db).reloadUser(), isTrue);

    final unverified = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'u2',
        email: 'b@alustudent.com',
        isEmailVerified: false,
      ),
    );
    expect(await AuthRepository(unverified, db).reloadUser(), isFalse);
  });
}
