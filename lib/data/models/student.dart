import 'package:cairo_coding_app/data/models/certificate.dart';
import 'package:equatable/equatable.dart';

class Student extends Equatable {
  const Student({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.groupIds,
    required this.active,
    this.lastSeenAt,
    this.createdAt,
    this.certificates = const [],
  });

  factory Student.fromMap(String uid, Map<String, dynamic> map) => Student(
    uid: uid,
    name: map['name'] as String? ?? '',
    email: map['email'] as String,
    phone: map['phone'] as String? ?? '',
    groupIds: List<String>.from(map['groupIds'] as List? ?? const []),
    active: map['active'] as bool? ?? true,
    lastSeenAt: _date(map['lastSeenAt']),
    createdAt: _date(map['createdAt']),
    certificates: [
      for (final item in map['certificates'] as List? ?? const [])
        Certificate.fromMap(Map<String, dynamic>.from(item as Map)),
    ],
  );

  static DateTime? _date(Object? millis) => millis is int ? DateTime.fromMillisecondsSinceEpoch(millis) : null;

  final String uid;
  final String name;
  final String email;
  final String phone;
  final List<String> groupIds;
  final bool active;

  /// When the student last opened the app; null means they never signed in yet.
  final DateTime? lastSeenAt;
  final DateTime? createdAt;

  /// Issued by the admin from "Edit student"; written only by [AcademySource.updateStudent], never by [toMap].
  final List<Certificate> certificates;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'groupIds': groupIds,
    'active': active,
  };

  Student copyWith({
    String? name,
    String? phone,
    List<String>? groupIds,
    bool? active,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    List<Certificate>? certificates,
  }) => Student(
    uid: uid,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    groupIds: groupIds ?? this.groupIds,
    active: active ?? this.active,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    createdAt: createdAt ?? this.createdAt,
    certificates: certificates ?? this.certificates,
  );

  @override
  List<Object?> get props => [uid, name, email, phone, groupIds, active, lastSeenAt, createdAt, certificates];
}

class NewStudent extends Equatable {
  const NewStudent({required this.email, this.name = '', this.phone = ''});

  final String email;
  final String name;
  final String phone;

  @override
  List<Object> get props => [email, name, phone];
}

class AddStudentsResult extends Equatable {
  const AddStudentsResult({required this.created, required this.linked, this.skipped = const []});

  final int created;
  final int linked;
  final List<String> skipped;

  @override
  List<Object> get props => [created, linked, skipped];
}
