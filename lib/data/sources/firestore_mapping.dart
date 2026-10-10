import 'package:cloud_firestore/cloud_firestore.dart';

const Set<String> _dateFields = {'startDate', 'endDate', 'startsAt', 'recordedAt', 'createdAt', 'updatedAt'};

Map<String, dynamic> fromFirestore(Map<String, dynamic> data) => {
  for (final MapEntry(:key, :value) in data.entries) key: value is Timestamp ? value.millisecondsSinceEpoch : value,
};

Map<String, dynamic> toFirestore(Map<String, dynamic> map) => {
  for (final MapEntry(:key, :value) in map.entries)
    key: _dateFields.contains(key) && value is int ? Timestamp.fromMillisecondsSinceEpoch(value) : value,
};
