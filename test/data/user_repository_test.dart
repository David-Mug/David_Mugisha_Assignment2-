import 'package:campus_incident/data/user_repository.dart';
import 'package:campus_incident/models/app_user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late UserRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = UserRepository(db);
    await db.collection('users').doc('u1').set({
      'fullName': 'Amina Hassan',
      'email': 'amina@alustudent.com',
      'role': 'staff',
    });
  });

  test('watchUser maps the document, or null when missing', () async {
    final user = await repo.watchUser('u1').first;
    expect(user!.fullName, 'Amina Hassan');
    expect(user.role, UserRole.staff);

    expect(await repo.watchUser('missing').first, isNull);
  });

  test('updateProfile changes only the given fields', () async {
    await repo.updateProfile('u1', fullName: ' Amina H. ');

    final data = (await db.collection('users').doc('u1').get()).data()!;
    expect(data['fullName'], 'Amina H.');
    expect(data['role'], 'staff');
    expect(data.containsKey('photoUrl'), isFalse);
    expect(data['updatedAt'], isNotNull);
  });
}
