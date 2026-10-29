import 'package:equatable/equatable.dart';

class Course extends Equatable {
  const Course({required this.id, required this.name, this.sessionTitles = const [], this.instructorIds = const []});

  factory Course.fromMap(String id, Map<String, dynamic> map) => Course(
    id: id,
    name: map['name'] as String? ?? '',
    sessionTitles: List<String>.from(map['sessionTitles'] as List? ?? const []),
    instructorIds: List<String>.from(map['instructorIds'] as List? ?? const []),
  );

  final String id;
  final String name;

  /// The course plan in teaching order: session n is `sessionTitles[n - 1]`.
  final List<String> sessionTitles;
  final List<String> instructorIds;

  String? titleOf(int? number) =>
      number != null && number >= 1 && number <= sessionTitles.length ? sessionTitles[number - 1] : null;

  Map<String, dynamic> toMap() => {'name': name, 'sessionTitles': sessionTitles, 'instructorIds': instructorIds};

  Course copyWith({String? id, String? name, List<String>? sessionTitles, List<String>? instructorIds}) => Course(
    id: id ?? this.id,
    name: name ?? this.name,
    sessionTitles: sessionTitles ?? this.sessionTitles,
    instructorIds: instructorIds ?? this.instructorIds,
  );

  @override
  List<Object> get props => [id, name, sessionTitles, instructorIds];
}
