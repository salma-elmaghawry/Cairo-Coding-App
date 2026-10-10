import 'package:equatable/equatable.dart';

class Recording extends Equatable {
  const Recording({
    required this.id,
    required this.groupId,
    required this.title,
    required this.sessionNumber,
    required this.url,
    required this.recordedAt,
  });

  factory Recording.fromMap(String id, Map<String, dynamic> map) => Recording(
    id: id,
    groupId: map['groupId'] as String,
    title: map['title'] as String,
    sessionNumber: map['sessionNumber'] as int,
    url: map['url'] as String,
    recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt'] as int),
  );

  final String id;
  final String groupId;
  final String title;
  final int sessionNumber;
  final String url;
  final DateTime recordedAt;

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'title': title,
    'sessionNumber': sessionNumber,
    'url': url,
    'recordedAt': recordedAt.millisecondsSinceEpoch,
  };

  Recording copyWith({String? id}) => Recording(
    id: id ?? this.id,
    groupId: groupId,
    title: title,
    sessionNumber: sessionNumber,
    url: url,
    recordedAt: recordedAt,
  );

  @override
  List<Object> get props => [id, groupId, title, sessionNumber, url, recordedAt];
}
