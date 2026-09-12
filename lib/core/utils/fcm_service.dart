import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FCMService {
  static const String _scopes = 'https://www.googleapis.com/auth/firebase.messaging';
  
  static Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString('lib/service_account.json');
      final credentials = ServiceAccountCredentials.fromJson(jsonString);
      
      final client = await clientViaServiceAccount(credentials, [_scopes]);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint("Error getting FCM access token: $e");
      return null;
    }
  }

  static Future<String?> _getProjectId() async {
    try {
      final jsonString = await rootBundle.loadString('lib/service_account.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return data['project_id'];
    } catch (e) {
      debugPrint("Error getting Project ID: $e");
      return null;
    }
  }

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final projectId = await _getProjectId();
      
      if (accessToken == null || projectId == null) {
        debugPrint("FCM ERROR: Missing token or project ID.");
        return;
      }

      final endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'notification': {
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("? FCM Push Notification sent successfully!");
      } else {
        debugPrint("? FCM Push Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("FCM Exception: $e");
    }
  }
}
