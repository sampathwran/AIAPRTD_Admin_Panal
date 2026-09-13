import 'dart:html' as html;

void redirectIfTrackId() {
  final uri = Uri.tryParse(html.window.location.href);
  if (uri != null && uri.queryParameters.containsKey('id') && !uri.path.contains('track')) {
    final id = uri.queryParameters['id'];
    html.window.location.href = '/track?id=';
  }
}
