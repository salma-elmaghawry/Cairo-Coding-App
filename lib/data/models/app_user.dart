import 'package:cairo_coding_app/data/models/student.dart';
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({required this.profile, required this.isAdmin});

  final Student profile;
  final bool isAdmin;

  String get uid => profile.uid;

  bool get canUseStudentApp => profile.active && profile.groupIds.isNotEmpty;

  @override
  List<Object> get props => [profile, isAdmin];
}
