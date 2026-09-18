import 'dart:io';

void main() {
  final file = File('lib/features/driver/drivers_overview/sub_panels/driver_profile_dialog.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    "Widget _buildInactiveReasonsList(String memberId) {",
    "Widget _buildInactiveReasonsList(String membershipNo, String uid) {"
  );
  
  content = content.replaceAll(
    "if (memberId.isEmpty) return const SizedBox.shrink();",
    "if (membershipNo.isEmpty && uid.isEmpty) return const SizedBox.shrink();"
  );
  
  content = content.replaceAll(
    "child: _buildInactiveReasonsList(driver['doc_id'] ?? driver['uid'] ?? driver['membershipNo'] ?? ''),",
    "child: _buildInactiveReasonsList(driver['membershipNo']?.toString() ?? '', driver['uid']?.toString() ?? driver['doc_id']?.toString() ?? ''),"
  );

  content = content.replaceAll(
    "return FutureBuilder<DocumentSnapshot>(",
    "return FutureBuilder<QuerySnapshot>("
  );

  content = content.replaceAll(
    "future: FirebaseFirestore.instance.collection('member_inactive_reasons').doc(memberId).get(),",
    "future: uid.isNotEmpty ? FirebaseFirestore.instance.collection('member_inactive_reasons').where('uid', isEqualTo: uid).limit(1).get() : FirebaseFirestore.instance.collection('member_inactive_reasons').where('membershipNo', isEqualTo: membershipNo).limit(1).get(),"
  );

  content = content.replaceAll(
    "if (!snapshot.hasData || !snapshot.data!.exists) {",
    "if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {"
  );

  content = content.replaceAll(
    "final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};",
    "final data = snapshot.data!.docs.first.data() as Map<String, dynamic>? ?? {};"
  );

  file.writeAsStringSync(content);
  print('Updated profile dialog to use QuerySnapshot');
}
