import 'package:cairo_coding_app/core/error_handling/error_mapper.dart';
import 'package:cairo_coding_app/core/error_handling/failures.dart';

sealed class Result<T> {
  const Result();

  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (error) {
      return Err(ErrorMapper.map(error));
    }
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
