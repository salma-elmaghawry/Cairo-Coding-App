import 'package:equatable/equatable.dart';

/// A message from the academy to one or more groups, shown in the student app.
class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.groupIds,
    required this.createdAt,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) => Announcement(
    id: id,
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    groupIds: List<String>.from(map['groupIds'] as List? ?? const []),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
  );

  final String id;
  final String title;
  final String body;

  /// Every group it was sent to; each group holds its own copy.
  final List<String> groupIds;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'groupIds': groupIds,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  Announcement copyWith({String? id}) =>
      Announcement(id: id ?? this.id, title: title, body: body, groupIds: groupIds, createdAt: createdAt);

  @override
  List<Object> get props => [id, title, body, groupIds, createdAt];
}
