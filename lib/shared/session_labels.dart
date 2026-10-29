import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:easy_localization/easy_localization.dart';

extension SessionLabels on ClassSession {
  String get title => number == null ? 'session.extra_title'.tr() : 'session.title'.tr(args: ['$number']);

  /// "Operators by Eng. Salma", or whichever half is set; empty when neither is.
  /// Both names are isolated because the line mixes them with Arabic words.
  String get topicLine => [
    if (topic.isNotEmpty) topic.isolated,
    if (instructor.isNotEmpty) (topic.isEmpty ? 'session.with' : 'session.by').tr(args: [instructor.isolated]),
  ].join(' ');

  String get durationLabel {
    final hours = durationMin ~/ 60;
    final minutes = durationMin % 60;
    if (hours == 0) return 'session.minutes'.tr(args: ['$minutes']);
    if (minutes == 0) return 'session.hours'.tr(args: ['$hours']);
    return 'session.duration'.tr(args: ['$hours', '$minutes']);
  }

  (String, StatusTone)? get statusBadge => switch (status) {
    SessionStatus.scheduled => null,
    SessionStatus.moved => ('session.status.moved'.tr(), StatusTone.neutral),
    SessionStatus.extra => ('session.status.extra'.tr(), StatusTone.accent),
    SessionStatus.cancelled => ('session.status.cancelled'.tr(), StatusTone.danger),
  };
}
