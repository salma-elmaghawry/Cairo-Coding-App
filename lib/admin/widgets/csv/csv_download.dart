import 'package:cairo_coding_app/admin/widgets/csv/save_file_stub.dart'
    if (dart.library.js_interop) 'package:cairo_coding_app/admin/widgets/csv/save_file_web.dart'
    as platform;

/// Hands [rows] to the browser as a CSV download. False where there's no browser, such as in tests.
bool downloadCsv(String fileName, List<List<Object?>> rows) => platform.saveTextFile(fileName, toCsv(rows));

/// Starts with a byte-order mark, so Excel reads Arabic names correctly.
String toCsv(List<List<Object?>> rows) => '﻿${rows.map((row) => row.map(_cell).join(',')).join('\r\n')}';

String _cell(Object? value) {
  final text = '${value ?? ''}';
  return RegExp(r'[",\r\n]').hasMatch(text) ? '"${text.replaceAll('"', '""')}"' : text;
}
