import 'package:equatable/equatable.dart';

enum SessionStatus { scheduled, moved, extra, cancelled }

class ClassSession extends Equatable {
  const ClassSession({
    required this.id,
    required this.groupId,
    required this.startsAt,
    required this.durationMin,
    this.number,
    this.status = SessionStatus.scheduled,
    this.meetingLinkOverride,
    this.topic = '',
    this.instructor = '',
  });

  factory ClassSession.fromMap(String id, Map<String, dynamic> map) => ClassSession(
    id: id,
    groupId: map['groupId'] as String,
    number: map['number'] as int?,
    startsAt: DateTime.fromMillisecondsSinceEpoch(map['startsAt'] as int),
    durationMin: map['durationMin'] as int,
    status: SessionStatus.values.asNameMap()[map['status']] ?? SessionStatus.scheduled,
    meetingLinkOverride: map['meetingLinkOverride'] as String?,
    topic: map['topic'] as String? ?? '',
    instructor: map['instructor'] as String? ?? '',
  );

  final String id;
  final String groupId;
  final int? number;
  final DateTime startsAt;
  final int durationMin;
  final SessionStatus status;
  final String? meetingLinkOverride;
  final String topic;
  final String instructor;

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMin));

  bool get isCancelled => status == SessionStatus.cancelled;

  bool isPast(DateTime now) => endsAt.isBefore(now);

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'number': number,
    'startsAt': startsAt.millisecondsSinceEpoch,
    'durationMin': durationMin,
    'status': status.name,
    'meetingLinkOverride': meetingLinkOverride,
    'topic': topic,
    'instructor': instructor,
  };

  ClassSession copyWith({String? id, DateTime? startsAt, SessionStatus? status, String? topic, String? instructor}) {
    return ClassSession(
      id: id ?? this.id,
      groupId: groupId,
      number: number,
      startsAt: startsAt ?? this.startsAt,
      durationMin: durationMin,
      status: status ?? this.status,
      meetingLinkOverride: meetingLinkOverride,
      topic: topic ?? this.topic,
      instructor: instructor ?? this.instructor,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    number,
    startsAt,
    durationMin,
    status,
    meetingLinkOverride,
    topic,
    instructor,
  ];
}
