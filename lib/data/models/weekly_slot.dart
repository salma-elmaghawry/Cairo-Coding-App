import 'package:equatable/equatable.dart';

class WeeklySlot extends Equatable {
  const WeeklySlot({required this.weekday, required this.hour, required this.minute, required this.durationMin});

  factory WeeklySlot.fromMap(Map<String, dynamic> map) => WeeklySlot(
    weekday: map['weekday'] as int,
    hour: map['hour'] as int,
    minute: map['minute'] as int,
    durationMin: map['durationMin'] as int,
  );

  final int weekday;
  final int hour;
  final int minute;
  final int durationMin;

  int get minuteOfDay => hour * 60 + minute;

  Map<String, dynamic> toMap() => {'weekday': weekday, 'hour': hour, 'minute': minute, 'durationMin': durationMin};

  @override
  List<Object> get props => [weekday, hour, minute, durationMin];
}
