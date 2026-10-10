import 'package:equatable/equatable.dart';

class Student extends Equatable {
  const Student({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.groupIds,
    required this.active,
  });

  factory Student.fromMap(String uid, Map<String, dynamic> map) => Student(
    uid: uid,
    name: map['name'] as String? ?? '',
    email: map['email'] as String,
    phone: map['phone'] as String? ?? '',
    groupIds: List<String>.from(map['groupIds'] as List? ?? const []),
    active: map['active'] as bool? ?? true,
  );

  final String uid;
  final String name;
  final String email;
  final String phone;
  final List<String> groupIds;
  final bool active;

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

  Student copyWith({List<String>? groupIds, bool? active}) => Student(
    uid: uid,
    name: name,
    email: email,
    phone: phone,
    groupIds: groupIds ?? this.groupIds,
    active: active ?? this.active,
  );

  @override
  List<Object> get props => [uid, name, email, phone, groupIds, active];
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
