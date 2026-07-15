import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  /// Logs an activation action (Approve/Reject) to the 'activation_history' collection.
  static Future<void> logActivationAction({
    required String type,
    required String membershipNo,
    required String status,
    required Map<String, dynamic> requestData,
    String? remarks,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('activation_history').add({
        'type': type,
        'membershipNo': membershipNo,
        'status': status,
        'requestData': requestData,
        'remarks': remarks ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ History saved successfully for $membershipNo ($type - $status)");
    } catch (e) {
      debugPrint("❌ Failed to save history: $e");
    }
  }
}
