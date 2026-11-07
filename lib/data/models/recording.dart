import 'package:equatable/equatable.dart';

class Recording extends Equatable {
  const Recording({
    required this.id,
    required this.groupId,
    required this.title,
    required this.sessionNumber,
    required this.url,
    required this.recordedAt,
    this.durationMin = 0,
    this.viewers = const [],
    this.addedAt,
  });

  factory Recording.fromMap(String id, Map<String, dynamic> map) => Recording(
    id: id,
    groupId: map['groupId'] as String,
    title: map['title'] as String,
    sessionNumber: map['sessionNumber'] as int,
    url: map['url'] as String,
    recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt'] as int),
    durationMin: map['durationMin'] as int? ?? 0,
    viewers: List<String>.from(map['viewers'] as List? ?? const []),
    addedAt: map['createdAt'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  );

  final String id;
  final String groupId;
  final String title;
  final int sessionNumber;
  final String url;
  final DateTime recordedAt;

  /// Length of the video in minutes; 0 when the admin didn't enter it.
  final int durationMin;

  /// Students who opened it, by uid. Written on its own ([AcademySource.markViewed]), never by [toMap].
  final List<String> viewers;

  /// When the admin added it, set by the server.
  final DateTime? addedAt;

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'title': title,
    'sessionNumber': sessionNumber,
    'url': url,
    'recordedAt': recordedAt.millisecondsSinceEpoch,
    'durationMin': durationMin,
  };

  Recording copyWith({String? id, List<String>? viewers, DateTime? addedAt}) => Recording(
    id: id ?? this.id,
    groupId: groupId,
    title: title,
    sessionNumber: sessionNumber,
    url: url,
    recordedAt: recordedAt,
    durationMin: durationMin,
    viewers: viewers ?? this.viewers,
    addedAt: addedAt ?? this.addedAt,
  );

  @override
  List<Object?> get props => [id, groupId, title, sessionNumber, url, recordedAt, durationMin, viewers, addedAt];
}
