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
    this.manual = false,
    this.attendees,
    this.taskDoneBy,
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
    manual: map['manual'] as bool? ?? false,
    attendees: map['attendees'] == null ? null : List<String>.from(map['attendees'] as List),
    taskDoneBy: map['taskDoneBy'] == null ? null : List<String>.from(map['taskDoneBy'] as List),
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

  /// Added by hand from the dashboard, so regenerating the weekly slots never replaces it.
  final bool manual;

  /// Students who joined the live call, by uid. Null until anyone joins or the admin takes attendance, which
  /// tells a session nobody attended apart from one from before attendance was recorded.
  /// Written on its own ([AcademySource.markAttended], [AcademySource.setAttendance]), never by [toMap].
  final List<String>? attendees;

  bool get hasAttendance => attendees != null;

  /// Students who handed in this session's task, by uid, ticked by the admin. Null means the session had no
  /// task, so it's left out of the tasks rate. Written only by [AcademySource.setTaskDoneBy], never by [toMap].
  final List<String>? taskDoneBy;

  bool get hasTask => taskDoneBy != null;

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
    'manual': manual,
  };

  ClassSession copyWith({
    String? id,
    int? number,
    DateTime? startsAt,
    SessionStatus? status,
    String? meetingLinkOverride,
    String? topic,
    String? instructor,
    List<String>? attendees,
  }) {
    return ClassSession(
      id: id ?? this.id,
      groupId: groupId,
      number: number ?? this.number,
      startsAt: startsAt ?? this.startsAt,
      durationMin: durationMin,
      status: status ?? this.status,
      meetingLinkOverride: meetingLinkOverride ?? this.meetingLinkOverride,
      topic: topic ?? this.topic,
      instructor: instructor ?? this.instructor,
      manual: manual,
      attendees: attendees ?? this.attendees,
      taskDoneBy: taskDoneBy,
    );
  }

  /// [copyWith] can't clear a field, and a task can be taken off a session.
  ClassSession withTaskDoneBy(List<String>? uids) => ClassSession(
    id: id,
    groupId: groupId,
    number: number,
    startsAt: startsAt,
    durationMin: durationMin,
    status: status,
    meetingLinkOverride: meetingLinkOverride,
    topic: topic,
    instructor: instructor,
    manual: manual,
    attendees: attendees,
    taskDoneBy: uids,
  );

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
    manual,
    attendees,
    taskDoneBy,
  ];
}
