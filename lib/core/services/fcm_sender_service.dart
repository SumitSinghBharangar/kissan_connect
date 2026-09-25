import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMSenderService {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  /// Get temporary OAuth 2.0 access token from service account credentials
  static Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final serviceAccountJson = json.decode(jsonString);

      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );

      final client = await clientViaServiceAccount(credentials, _scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Sends a push notification directly to another user by their User ID
  static Future<void> sendPushNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String route = '',
  }) async {
    try {
      // 1. Fetch recipient's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUserId)
          .get();

      if (!userDoc.exists || userDoc.data() == null) return;

      final fcmToken = userDoc.data()!['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;

      // 2. Read the project ID from the service account
      final jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final projectData = json.decode(jsonString);
      final projectId = projectData['project_id'];

      // 3. Acquire short-lived OAuth2 Token
      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      // 4. Construct the FCM v1 JSON payload
      final endpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': {'route': route},
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'kissan_connect_channel',
              'sound': 'default',
            },
          },
        },
      };

      // 5. Send POST request directly to Google FCM server
      await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(payload),
      );
    } catch (_) {
      // Handle network exceptions gracefully
    }
  }
}
