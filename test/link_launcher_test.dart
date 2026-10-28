import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseLink', () {
    test('keeps a full link as is', () {
      expect(parseLink('https://meet.google.com/abc-defg-hij').toString(), 'https://meet.google.com/abc-defg-hij');
    });

    test('adds https to a link pasted without a scheme', () {
      expect(parseLink('  us05web.zoom.us/j/8123456789?pwd=abc ').toString(), 'https://us05web.zoom.us/j/8123456789?pwd=abc');
    });

    test('pulls the link out of a pasted Zoom invitation', () {
      const invite = 'Join Zoom Meeting\nhttps://us05web.zoom.us/j/8123456789?pwd=abc\n\nMeeting ID: 812 345 6789';
      expect(parseLink(invite).toString(), 'https://us05web.zoom.us/j/8123456789?pwd=abc');
    });

    test('rejects empty or plain text', () {
      expect(parseLink(''), isNull);
      expect(parseLink('ask the instructor'), isNull);
    });
  });

  group('zoomAppUri', () {
    test('turns a Zoom meeting link into a zoommtg join link', () {
      final uri = zoomAppUri(Uri.parse('https://us05web.zoom.us/j/8123456789?pwd=abc'))!;
      expect(uri.scheme, 'zoommtg');
      expect(uri.queryParameters, {'action': 'join', 'confno': '8123456789', 'pwd': 'abc'});
    });

    test('works without a passcode', () {
      expect(zoomAppUri(Uri.parse('https://zoom.us/j/8123456789'))!.queryParameters, {
        'action': 'join',
        'confno': '8123456789',
      });
    });

    test('leaves other links alone', () {
      expect(zoomAppUri(Uri.parse('https://meet.google.com/abc-defg-hij')), isNull);
      expect(zoomAppUri(Uri.parse('https://zoom.us/pricing')), isNull);
    });
  });
}
