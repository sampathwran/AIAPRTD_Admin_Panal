import 'dart:io';

void main() {
  final file = File('lib/features/driver/drivers_overview/sub_panels/driver_profile_dialog.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    "buffer.writeln('? \$formattedKey: \${value.toString().toUpperCase()}');",
    "buffer.writeln('? \$formattedKey: \${value.toString().replaceAll(\\'_\\', \\' \\').toUpperCase()}');"
  );
  
  file.writeAsStringSync(content);
  print('Updated copy text');
}
