import 'dart:io';

void main() {
  final file = File('lib/features/driver/drivers_overview/sub_panels/driver_profile_dialog.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    "Widget _buildInactiveReasonsList(String membershipNo) {",
    "Widget _buildInactiveReasonsList(String memberId) {"
  );
  
  content = content.replaceAll(
    "if (membershipNo.isEmpty) return const SizedBox.shrink();",
    "if (memberId.isEmpty) return const SizedBox.shrink();"
  );
  
  content = content.replaceAll(
    "FirebaseFirestore.instance.collection('member_inactive_reasons').doc(membershipNo).get()",
    "FirebaseFirestore.instance.collection('member_inactive_reasons').doc(memberId).get()"
  );

  content = content.replaceAll(
    "child: _buildInactiveReasonsList(driver['membershipNo'] ?? driver['doc_id'] ?? driver['uid'] ?? ''),",
    "child: _buildInactiveReasonsList(driver['doc_id'] ?? driver['uid'] ?? driver['membershipNo'] ?? ''),"
  );

  content = content.replaceAll(
    "reasonWidgets.add(_buildReasonRow(formattedKey, value.toString(), false));",
    "reasonWidgets.add(_buildReasonRow(formattedKey, value.toString().replaceAll('_', ' ').toUpperCase(), false));"
  );
  
  file.writeAsStringSync(content);
  print('Updated driver_profile_dialog.dart');
}
