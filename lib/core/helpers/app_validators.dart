import 'package:easy_localization/easy_localization.dart';

class AppValidators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'auth.signup.name_required'.tr();
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'auth.login.email_required'.tr();
    }
    final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'auth.login.email_invalid'.tr();
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.login.password_required'.tr();
    }

    if (value.length < 6) {
      return 'auth.login.password_length'.tr();
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'auth.login.password_required'.tr();
    }

    if (value != password) {
      return 'auth.signup.password_mismatch'.tr();
    }

    return null;
  }

  static bool hasMinimumLength(String password) => password.length >= 8;

  static bool hasMixedCase(String password) => RegExp(r'(?=.*[A-Z])(?=.*[a-z])').hasMatch(password);

  static bool hasDigit(String password) => RegExp(r'\d').hasMatch(password);

  static bool hasSpecialCharacter(String password) => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    return emailRegex.hasMatch(email);
  }
}
