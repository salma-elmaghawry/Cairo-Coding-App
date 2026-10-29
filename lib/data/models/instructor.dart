import 'package:equatable/equatable.dart';

class Instructor extends Equatable {
  const Instructor({required this.id, required this.name, this.email = '', this.phone = '', this.groupIds = const []});

  factory Instructor.fromMap(String id, Map<String, dynamic> map) => Instructor(
    id: id,
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    groupIds: List<String>.from(map['groupIds'] as List? ?? const []),
  );

  final String id;
  final String name;
  final String email;
  final String phone;

  /// The groups this instructor is teaching, archived ones included.
  final List<String> groupIds;

  Map<String, dynamic> toMap() => {'name': name, 'email': email, 'phone': phone, 'groupIds': groupIds};

  Instructor copyWith({String? id, String? name, String? email, String? phone, List<String>? groupIds}) => Instructor(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    groupIds: groupIds ?? this.groupIds,
  );

  @override
  List<Object> get props => [id, name, email, phone, groupIds];
}
