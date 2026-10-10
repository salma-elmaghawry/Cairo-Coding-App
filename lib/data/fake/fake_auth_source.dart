import 'dart:async';

import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/error_handling/app_exceptions.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/sources/auth_source.dart';

class FakeAuthSource implements AuthSource {
  FakeAuthSource(this._store, this._flavor);

  final FakeAcademyStore _store;
  final AppFlavor _flavor;
  String? _signedInEmail;

  static const Student _admin = Student(
    uid: 'admin_1',
    name: 'Salma',
    email: FakeAcademyStore.demoAdminEmail,
    phone: '',
    groupIds: [],
    active: true,
  );

  AppUser? _currentUser() {
    final email = _signedInEmail;
    if (email == null) return null;
    if (_flavor.isAdmin) return const AppUser(profile: _admin, isAdmin: true);
    final student = _store.studentByEmail(email);
    return student == null ? null : AppUser(profile: student, isAdmin: false);
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    yield* _store.watch(_currentUser).distinct();
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final knownEmail = _flavor.isAdmin || _store.studentByEmail(email) != null;
    if (!knownEmail || password.length < 6) throw const InvalidCredentialsException();
    _signedInEmail = email.trim().toLowerCase();
    _store.notify();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> signOut() async {
    _signedInEmail = null;
    _store.notify();
  }
}
