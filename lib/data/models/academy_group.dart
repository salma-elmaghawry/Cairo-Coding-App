import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:equatable/equatable.dart';

class AcademyGroup extends Equatable {
  const AcademyGroup({
    required this.id,
    required this.name,
    required this.track,
    required this.meetingLink,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.weeklySlots = const [],
    this.archived = false,
  });

  factory AcademyGroup.fromMap(String id, Map<String, dynamic> map) => AcademyGroup(
    id: id,
    name: map['name'] as String,
    track: map['track'] as String? ?? '',
    meetingLink: map['meetingLink'] as String? ?? '',
    location: map['location'] as String? ?? '',
    startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
    endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int),
    weeklySlots: (map['weeklySlots'] as List? ?? const [])
        .map((slot) => WeeklySlot.fromMap(Map<String, dynamic>.from(slot as Map)))
        .toList(),
    archived: map['archived'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String track;
  final String meetingLink;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final List<WeeklySlot> weeklySlots;
  final bool archived;

  Map<String, dynamic> toMap() => {
    'name': name,
    'track': track,
    'meetingLink': meetingLink,
    'location': location,
    'startDate': startDate.millisecondsSinceEpoch,
    'endDate': endDate.millisecondsSinceEpoch,
    'weeklySlots': weeklySlots.map((slot) => slot.toMap()).toList(),
    'archived': archived,
  };

  AcademyGroup copyWith({
    String? id,
    String? name,
    String? track,
    String? meetingLink,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    List<WeeklySlot>? weeklySlots,
    bool? archived,
  }) {
    return AcademyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      track: track ?? this.track,
      meetingLink: meetingLink ?? this.meetingLink,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weeklySlots: weeklySlots ?? this.weeklySlots,
      archived: archived ?? this.archived,
    );
  }

  @override
  List<Object> get props => [id, name, track, meetingLink, location, startDate, endDate, weeklySlots, archived];
}
