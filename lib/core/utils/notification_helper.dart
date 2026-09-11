import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationHelper {
  static Future<void> sendNotification({
    required String membershipNo,
    required String title,
    required String body,
  }) async {
    debugPrint("=== ADMIN_NOTIF_DEBUG: Sending notification to $membershipNo. Title: $title ===");
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetType': 'specific',
        'targetMembers': [membershipNo],
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("=== ADMIN_NOTIF_DEBUG: Successfully written to Firestore ===");
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }
}
