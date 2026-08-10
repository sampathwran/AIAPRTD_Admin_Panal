import 'dart:html' as html;

void downloadCsv(String fileName, String csvData) {
  final bytes = html.Blob([csvData], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
