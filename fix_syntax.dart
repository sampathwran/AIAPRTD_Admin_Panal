import 'dart:io';

void main() {
  final dir = Directory('lib/features/driver');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains("data(['status'] == 'pending' || ['status'] == 'pending_approval')")) {
      content = content.replaceAll(
        "data(['status'] == 'pending' || ['status'] == 'pending_approval')",
        "(data['status'] == 'pending' || data['status'] == 'pending_approval')"
      );
      changed = true;
    }
    
    if (content.contains("d(['status'] == 'pending' || ['status'] == 'pending_approval')")) {
      content = content.replaceAll(
        "d(['status'] == 'pending' || ['status'] == 'pending_approval')",
        "(d['status'] == 'pending' || d['status'] == 'pending_approval')"
      );
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed ${file.path}');
    }
  }
}
