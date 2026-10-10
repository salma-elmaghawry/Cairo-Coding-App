import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/utils/stream_utils.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/sources/auth_source.dart';
import 'package:cairo_coding_app/data/sources/firestore_mapping.dart';
import 'package:cairo_coding_app/data/sources/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthSource implements AuthSource {
  FirebaseAuthSource(this._auth, this._db, this._flavor);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final AppFlavor _flavor;

  Student _fallbackProfile(User user) => Student(
    uid: user.uid,
    name: user.displayName ?? '',
    email: user.email ?? '',
    phone: '',
    groupIds: const [],
    active: false,
  );

  Stream<AppUser?> _watchAdmin(User user) => _db.collection(FirestorePaths.admins).doc(user.uid).snapshots().map((doc) {
    final data = doc.data();
    if (!doc.exists || data == null) return AppUser(profile: _fallbackProfile(user), isAdmin: false);
    return AppUser(
      profile: Student(
        uid: user.uid,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? user.email ?? '',
        phone: '',
        groupIds: const [],
        active: true,
      ),
      isAdmin: true,
    );
  });

  Stream<AppUser?> _watchStudent(User user) =>
      _db.collection(FirestorePaths.users).doc(user.uid).snapshots().map((doc) {
        final data = doc.data();
        final profile = data == null ? _fallbackProfile(user) : Student.fromMap(doc.id, fromFirestore(data));
        return AppUser(profile: profile, isAdmin: false);
      });

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().switchMap((user) {
    if (user == null) return Stream<AppUser?>.value(null);
    return _flavor.isAdmin ? _watchAdmin(user) : _watchStudent(user);
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();
}
