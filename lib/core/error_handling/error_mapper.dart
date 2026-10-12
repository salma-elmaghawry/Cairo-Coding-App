import 'dart:async';
import 'dart:io';

import 'package:cairo_coding_app/core/error_handling/app_exceptions.dart';
import 'package:cairo_coding_app/core/error_handling/failures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class ErrorMapper {
  static Failure map(Object error) {
    if (kDebugMode && error is! Failure) debugPrint('ErrorMapper ← ${error.runtimeType}: $error');
    if (error is FirebaseAuthException) return _mapAuth(error.code);
    if (error is FirebaseException) return _mapFirestore(error.code);

    return switch (error) {
      Failure() => error,
      InvalidCredentialsException() => InvalidCredentialsFailure('auth.errors.invalid_credentials'.tr()),
      NotAuthorizedException() => NotAuthorizedFailure('auth.errors.not_authorized'.tr()),
      NotSignedInException() => NotSignedInFailure('auth.errors.not_signed_in'.tr()),
      SocketException() || TimeoutException() => NetworkFailure('errors.network_error'.tr()),
      HttpException() || FormatException() => ServerFailure('errors.server_error'.tr()),
      _ => UnexpectedFailure('errors.unexpected_error'.tr()),
    };
  }

  static Failure _mapAuth(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' ||
    'user-disabled' => InvalidCredentialsFailure('auth.errors.invalid_credentials'.tr()),
    'too-many-requests' => ServerFailure('auth.errors.too_many_requests'.tr()),
    'network-request-failed' => NetworkFailure('errors.network_error'.tr()),
    _ => UnexpectedFailure('errors.unexpected_error'.tr()),
  };

  static Failure _mapFirestore(String code) => switch (code) {
    'permission-denied' || 'unauthenticated' => NotAuthorizedFailure('auth.errors.not_authorized'.tr()),
    'unavailable' || 'deadline-exceeded' => NetworkFailure('errors.network_error'.tr()),
    _ => ServerFailure('errors.server_error'.tr()),
  };

  static Stream<T> mapStream<T>(Stream<T> source) => source.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) => sink.addError(map(error), stackTrace),
    ),
  );
}
