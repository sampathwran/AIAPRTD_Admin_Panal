import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/fcm_service.dart';

class NotificationHelper {
  static Future<void> sendNotification({
    required String membershipNo,
    required String title,
    required String body,
  }) async {
    debugPrint("=== ADMIN_NOTIF_DEBUG: Sending notification to $membershipNo. Title: $title ===");
    try {
      // 1. Write to notifications collection (for in-app bell)
      await FirebaseFirestore.instance.collection('notifications').add({
        'targetType': 'specific',
        'targetMembers': [membershipNo],
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("=== ADMIN_NOTIF_DEBUG: Successfully written to Firestore ===");
      
      // 2. Fetch user's FCM Token and send Push Notification
      final querySnapshot = await FirebaseFirestore.instance
          .collection('member')
          .where('membershipNo', isEqualTo: membershipNo)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final fcmToken = userData['fcmToken'];
        
        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          debugPrint("=== ADMIN_NOTIF_DEBUG: Found FCM Token, sending push notification... ===");
          await FCMService.sendPushNotification(
            fcmToken: fcmToken,
            title: title,
            body: body,
          );
        } else {
          debugPrint("=== ADMIN_NOTIF_DEBUG: No FCM Token found for user $membershipNo ===");
        }
      }
      
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }
}
