import 'package:equatable/equatable.dart';

class Instructor extends Equatable {
  const Instructor({required this.id, required this.name});

  factory Instructor.fromMap(String id, Map<String, dynamic> map) =>
      Instructor(id: id, name: map['name'] as String? ?? '');

  final String id;
  final String name;

  Map<String, dynamic> toMap() => {'name': name};

  Instructor copyWith({String? id, String? name}) => Instructor(id: id ?? this.id, name: name ?? this.name);

  @override
  List<Object> get props => [id, name];
}
