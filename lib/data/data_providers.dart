import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_source.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/fake/fake_auth_source.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:cairo_coding_app/data/repositories/academy_repository.dart';
import 'package:cairo_coding_app/data/repositories/auth_repository.dart';
import 'package:cairo_coding_app/data/sources/academy_source.dart';
import 'package:cairo_coding_app/data/sources/auth_source.dart';
import 'package:cairo_coding_app/data/sources/firebase_auth_source.dart';
import 'package:cairo_coding_app/data/sources/firestore_academy_source.dart';
import 'package:cairo_coding_app/data/sources/student_account_creator.dart';
import 'package:cairo_coding_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final academySourceProvider = Provider<AcademySource>(
  (ref) => FirestoreAcademySource(
    ref.watch(firestoreProvider),
    StudentAccountCreator(DefaultFirebaseOptions.currentPlatform),
  ),
);

final authSourceProvider = Provider<AuthSource>(
  (ref) =>
      FirebaseAuthSource(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider), ref.watch(appFlavorProvider)),
);

final fakeAcademyStoreProvider = Provider<FakeAcademyStore>((ref) => FakeAcademyStore());

final fakeSourceOverrides = [
  academySourceProvider.overrideWith((ref) => FakeAcademySource(ref.watch(fakeAcademyStoreProvider))),
  authSourceProvider.overrideWith(
    (ref) => FakeAuthSource(ref.watch(fakeAcademyStoreProvider), ref.watch(appFlavorProvider)),
  ),
];

final academyRepositoryProvider = Provider<AcademyRepository>(
  (ref) => AcademyRepository(ref.watch(academySourceProvider), clock: ref.watch(clockProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(authSourceProvider)));

final authStateProvider = StreamProvider<AppUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());
