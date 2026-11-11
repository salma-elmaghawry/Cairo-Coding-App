import 'package:equatable/equatable.dart';

/// A certificate the academy issued to a student: a link to the file (Drive or PDF), since Spark has no Storage.
/// Saved inside `users/{uid}.certificates`, with the date as `yyyy-MM-dd` so it reads well in the console.
class Certificate extends Equatable {
  const Certificate({required this.title, required this.url, this.issuedOn});

  factory Certificate.fromMap(Map<String, dynamic> map) => Certificate(
    title: map['title'] as String? ?? '',
    url: map['url'] as String? ?? '',
    issuedOn: DateTime.tryParse(map['issuedOn'] as String? ?? ''),
  );

  /// Usually the diploma's name.
  final String title;
  final String url;
  final DateTime? issuedOn;

  Map<String, dynamic> toMap() => {
    'title': title,
    'url': url,
    if (issuedOn case final date?)
      'issuedOn': '${date.year}-${'${date.month}'.padLeft(2, '0')}-${'${date.day}'.padLeft(2, '0')}',
  };

  @override
  List<Object?> get props => [title, url, issuedOn];
}
