import 'package:cairo_coding_app/core/helpers/app_validators.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:easy_localization/easy_localization.dart';

/// [others] are the instructors the name must not repeat, so editing one leaves it out.
String? validateInstructorName(String? value, Iterable<Instructor> others) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'validation.required'.tr();
  if (others.any((i) => i.name.toLowerCase() == name.toLowerCase())) return 'admin.instructors.exists'.tr();
  return null;
}

/// Emails are saved in lower case, so the check for a repeat is too.
String? validateInstructorEmail(String? value, Iterable<Instructor> others) {
  final email = value?.trim().toLowerCase() ?? '';
  final invalid = AppValidators.validateEmail(email);
  if (invalid != null) return invalid;
  if (others.any((i) => i.email == email)) return 'admin.instructors.email_exists'.tr();
  return null;
}
