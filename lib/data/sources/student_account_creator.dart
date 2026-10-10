import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class StudentAccountCreator {
  StudentAccountCreator(this._options);

  static const String _appName = 'student-account-creator';

  final FirebaseOptions _options;

  Future<FirebaseAuth> _secondaryAuth() async {
    final app =
        Firebase.apps.where((a) => a.name == _appName).firstOrNull ??
        await Firebase.initializeApp(name: _appName, options: _options);
    return FirebaseAuth.instanceFor(app: app);
  }

  String _temporaryPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
    final random = Random.secure();
    return List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String?> createAccount(String email) async {
    final auth = await _secondaryAuth();
    try {
      final credential = await auth.createUserWithEmailAndPassword(email: email, password: _temporaryPassword());
      return credential.user?.uid;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') return null;
      rethrow;
    } finally {
      await auth.signOut();
    }
  }

  Future<void> sendWelcomeEmail(String email) async {
    final auth = await _secondaryAuth();
    await auth.sendPasswordResetEmail(email: email);
  }
}
