import 'package:equatable/equatable.dart';

class Instructor extends Equatable {
  const Instructor({required this.id, required this.name, this.email = '', this.groupIds = const []});

  factory Instructor.fromMap(String id, Map<String, dynamic> map) => Instructor(
    id: id,
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    groupIds: List<String>.from(map['groupIds'] as List? ?? const []),
  );

  final String id;
  final String name;
  final String email;

  /// The groups this instructor is teaching, archived ones included.
  final List<String> groupIds;

  Map<String, dynamic> toMap() => {'name': name, 'email': email, 'groupIds': groupIds};

  Instructor copyWith({String? id, String? name, String? email, List<String>? groupIds}) => Instructor(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    groupIds: groupIds ?? this.groupIds,
  );

  @override
  List<Object> get props => [id, name, email, groupIds];
}
