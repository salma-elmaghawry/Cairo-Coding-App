import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalLink(String url) async {
  final uri = parseLink(url);
  if (uri == null) return false;
  final zoomUri = zoomAppUri(uri);
  if (zoomUri != null && await _launch(zoomUri)) return true;
  return _launch(uri);
}

Future<bool> _launch(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}

/// Accepts what admins actually paste: a bare `zoom.us/j/…` without a scheme, or a whole
/// invitation text with the link somewhere inside it.
Uri? parseLink(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final link = RegExp(r'https?://\S+').firstMatch(trimmed)?.group(0) ?? trimmed;
  if (link.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(link.contains('://') ? link : 'https://$link');
  return (uri == null || uri.host.isEmpty) ? null : uri;
}

/// Rewrites a Zoom web link to the `zoommtg://` scheme so the Zoom app opens straight into the
/// meeting; returns null for anything else. The web link stays the fallback when Zoom isn't installed.
Uri? zoomAppUri(Uri uri) {
  final meetingId = RegExp(r'^/(?:j|w|wc/join)/(\d+)').firstMatch(uri.path)?.group(1);
  if (!uri.host.endsWith('zoom.us') || meetingId == null) return null;
  return Uri(
    scheme: 'zoommtg',
    host: 'zoom.us',
    path: '/join',
    queryParameters: {
      'action': 'join',
      'confno': meetingId,
      'pwd': ?uri.queryParameters['pwd'],
    },
  );
}
