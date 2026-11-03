import 'package:equatable/equatable.dart';

enum QuizStatus { draft, published }

class Quiz extends Equatable {
  const Quiz({
    required this.id,
    required this.title,
    this.description = '',
    this.coverUrl = '',
    this.groupIds = const [],
    this.durationMin = 0,
    required this.opensAt,
    required this.closesAt,
    this.maxAttempts = 1,
    this.status = QuizStatus.draft,
    this.questionCount = 0,
    this.totalPoints = 0,
  });

  factory Quiz.fromMap(String id, Map<String, dynamic> map) => Quiz(
    id: id,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    coverUrl: map['coverUrl'] as String? ?? '',
    groupIds: List<String>.from(map['groupIds'] as List? ?? const []),
    durationMin: map['durationMin'] as int? ?? 0,
    opensAt: DateTime.fromMillisecondsSinceEpoch(map['opensAt'] as int),
    closesAt: DateTime.fromMillisecondsSinceEpoch(map['closesAt'] as int),
    maxAttempts: map['maxAttempts'] as int? ?? 1,
    status: QuizStatus.values.asNameMap()[map['status']] ?? QuizStatus.draft,
    questionCount: map['questionCount'] as int? ?? 0,
    totalPoints: map['totalPoints'] as int? ?? 0,
  );

  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<String> groupIds;

  /// Minutes per attempt; 0 means no limit, so the quiz only ends when it closes.
  final int durationMin;
  final DateTime opensAt;
  final DateTime closesAt;
  final int maxAttempts;
  final QuizStatus status;
  final int questionCount;
  final int totalPoints;

  bool get isPublished => status == QuizStatus.published;

  bool get hasTimeLimit => durationMin > 0;

  bool hasOpened(DateTime now) => !now.isBefore(opensAt);

  bool hasClosed(DateTime now) => !now.isBefore(closesAt);

  bool isOpen(DateTime now) => hasOpened(now) && !hasClosed(now);

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'coverUrl': coverUrl,
    'groupIds': groupIds,
    'durationMin': durationMin,
    'opensAt': opensAt.millisecondsSinceEpoch,
    'closesAt': closesAt.millisecondsSinceEpoch,
    'maxAttempts': maxAttempts,
    'status': status.name,
    'questionCount': questionCount,
    'totalPoints': totalPoints,
  };

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<String>? groupIds,
    int? durationMin,
    DateTime? opensAt,
    DateTime? closesAt,
    int? maxAttempts,
    QuizStatus? status,
    int? questionCount,
    int? totalPoints,
  }) => Quiz(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    coverUrl: coverUrl ?? this.coverUrl,
    groupIds: groupIds ?? this.groupIds,
    durationMin: durationMin ?? this.durationMin,
    opensAt: opensAt ?? this.opensAt,
    closesAt: closesAt ?? this.closesAt,
    maxAttempts: maxAttempts ?? this.maxAttempts,
    status: status ?? this.status,
    questionCount: questionCount ?? this.questionCount,
    totalPoints: totalPoints ?? this.totalPoints,
  );

  @override
  List<Object> get props => [
    id,
    title,
    description,
    coverUrl,
    groupIds,
    durationMin,
    opensAt,
    closesAt,
    maxAttempts,
    status,
    questionCount,
    totalPoints,
  ];
}
