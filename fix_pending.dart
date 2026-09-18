import 'dart:io';

void main() {
  final dir = Directory('lib/features/driver');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains(".where('status', isEqualTo: 'pending')")) {
      content = content.replaceAll(
        ".where('status', isEqualTo: 'pending')",
        ".where('status', whereIn: ['pending', 'pending_approval'])"
      );
      changed = true;
    }

    if (content.contains(".where('kycApprovalStatus', isEqualTo: 'pending')")) {
      content = content.replaceAll(
        ".where('kycApprovalStatus', isEqualTo: 'pending')",
        ".where('kycApprovalStatus', whereIn: ['pending', 'pending_approval'])"
      );
      changed = true;
    }
    
    // For switch statements we need to add another case
    if (content.contains("case 'pending':")) {
      content = content.replaceAll("case 'pending':", "case 'pending':\n              case 'pending_approval':");
      changed = true;
    }
    
    if (content.contains("['status'] == 'pending'")) {
      content = content.replaceAll("['status'] == 'pending'", "(['status'] == 'pending' || ['status'] == 'pending_approval')");
      changed = true;
    }

    if (content.contains("status == 'pending'")) {
      content = content.replaceAll("status == 'pending'", "(status == 'pending' || status == 'pending_approval')");
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
