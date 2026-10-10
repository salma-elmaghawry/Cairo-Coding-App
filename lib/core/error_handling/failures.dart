sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure(super.message);
}

final class NotAuthorizedFailure extends Failure {
  const NotAuthorizedFailure(super.message);
}

final class NotSignedInFailure extends Failure {
  const NotSignedInFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
