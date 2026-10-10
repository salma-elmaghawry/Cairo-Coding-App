import 'package:cairo_coding_app/data/models/app_user.dart';

abstract class AuthSource {
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
