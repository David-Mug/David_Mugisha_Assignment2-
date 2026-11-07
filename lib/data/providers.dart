import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_status.dart';
import '../models/status_change.dart';
import 'auth_repository.dart';
import 'incident_repository.dart';
import 'storage_repository.dart';
import 'user_repository.dart';

// ------------------------------------------------------------ Firebase SDKs
// Wrapped in providers so tests can override them with fakes:
//   ProviderScope(overrides: [firestoreProvider.overrideWithValue(fake)])

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (_) => FirebaseStorage.instance,
);

// ------------------------------------------------------------ Repositories

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(ref.watch(firebaseStorageProvider)),
);

final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => IncidentRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageRepositoryProvider),
  ),
);

// ------------------------------------------------------------ Session state

/// The signed-in Firebase user, or null. Also re-emits when `emailVerified`
/// changes after a reload, which the router uses to leave the verify screen.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// The signed-in user's Firestore profile (name, role), or null when signed
/// out. Re-subscribes automatically when a different user signs in.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

// ------------------------------------------------------------ Incidents
// `autoDispose` closes the Firestore listener when no screen is showing it.

/// All campus reports, optionally filtered by status (null = all).
final incidentsProvider = StreamProvider.autoDispose
    .family<List<Incident>, IncidentStatus?>(
      (ref, status) =>
          ref.watch(incidentRepositoryProvider).watchAll(status: status),
    );

/// Reports submitted by the signed-in user.
final myIncidentsProvider = StreamProvider.autoDispose<List<Incident>>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchByReporter(uid);
});

final incidentProvider = StreamProvider.autoDispose.family<Incident?, String>(
  (ref, id) => ref.watch(incidentRepositoryProvider).watchIncident(id),
);

final statusHistoryProvider = StreamProvider.autoDispose
    .family<List<StatusChange>, String>(
      (ref, id) => ref.watch(incidentRepositoryProvider).watchHistory(id),
    );
