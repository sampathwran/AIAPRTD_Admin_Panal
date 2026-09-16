import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppTemplate {
  final String id;
  final String title;
  final String content;
  final bool isCustomMode;

  WhatsAppTemplate({
    required this.id,
    required this.title,
    required this.content,
    this.isCustomMode = false,
  });

  factory WhatsAppTemplate.fromMap(Map<String, dynamic> data) {
    return WhatsAppTemplate(
      id: data['id'] ?? data['docId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      isCustomMode: data['isCustomMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'isCustomMode': isCustomMode,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class WhatsAppTemplateService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('whatsapp_templates');

  Stream<List<WhatsAppTemplate>> getTemplatesStream() {
    return _collection.orderBy('createdAt').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return WhatsAppTemplate.fromMap(data);
      }).toList();
    });
  }

  Future<List<WhatsAppTemplate>> getTemplates() async {
    try {
      final snapshot = await _collection.orderBy('createdAt').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return WhatsAppTemplate.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> initializeDefaultsIfEmpty() async {
    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        // Create defaults
        await _collection.add({
          'title': 'Membership Number Notification',
          'content': 'ආයුබෝවන් {first_name} {last_name}.\n\nඔබගේ සාමාජික අංකය වන්නේ *{membership_no}* ය. ඉදිරියේදී සංගමය සමග කරන සෑම ගනුදෙනුවක් සහ සන්නිවේදන කටයුත්තක් සඳහාම ඔබගේ සාමාජික අංකය භාවිතා කරන්න.',
          'isCustomMode': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _collection.add({
          'title': 'Custom Message',
          'content': 'ආයුබෝවන් {first_name} {last_name}.\nඔබගේ සාමාජික අංකය: *{membership_no}*\n\n[ඔබගේ පණිවිඩය මෙතන ටයිප් කරන්න]',
          'isCustomMode': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _collection.add({
          'title': 'Inactive Warning',
          'content': 'ආයුබෝවන් {first_name} {last_name},\n\nඔබගේ සාමාජික අංකය වන්නේ {membership_no} ය.\n\nකරුණාකර ඔබගේ පහත සඳහන් විස්තර සම්පූර්ණ කර ගිණුම සක්‍රීය කර ගැනීමට කාරුණික වන්න:\n{inactive_reasons}\n\nඇප් එක ඩවුන්ලෝඩ් කරගැනීමට:\nhttps://play.google.com/store/apps/details?id=com.aiaprtd.driver\n\nඔබ සංගමයේ සාමාජිකත්වයෙන් සම්පූර්ණයෙන්ම ඉවත් වන්නේ නම් ඒ බව දැනුම් දීමට කාරුණික වන්න. එසේ නොමැති නම්, මෙම පණිවිඩය ලැබුණු මොහොතේ සිට ඉදිරියට මාස 3කින් පසු ඔබගේ AIAPRTD සාමාජිකත්වය ස්වයංක්‍රීයව අහෝසි වනු ඇත.',
          'isCustomMode': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Handle permission denied gracefully on UI
    }
  }

  Future<void> saveTemplate(WhatsAppTemplate template) async {
    final data = template.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _collection.add(data);
  }

  Future<void> updateTemplate(WhatsAppTemplate template) async {
    await _collection.doc(template.id).update(template.toMap());
  }

  Future<void> deleteTemplate(String id) async {
    await _collection.doc(id).delete();
  }
}
