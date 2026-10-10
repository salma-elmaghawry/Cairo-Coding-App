import 'package:cairo_coding_app/core/error_handling/error_mapper.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:cairo_coding_app/data/sources/auth_source.dart';

class AuthRepository {
  AuthRepository(this._source);

  final AuthSource _source;

  Stream<AppUser?> authStateChanges() => ErrorMapper.mapStream(_source.authStateChanges());

  Future<Result<void>> signIn({required String email, required String password}) =>
      Result.guard(() => _source.signIn(email: email.trim(), password: password));

  Future<Result<void>> sendPasswordReset(String email) => Result.guard(() => _source.sendPasswordReset(email.trim()));

  Future<Result<void>> signOut() => Result.guard(_source.signOut);
}
