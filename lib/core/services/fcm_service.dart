import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level function executed when the app is terminated or in background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background FCM message: ${message.messageId}");
}

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // 1. Initialize FCM and notification channels
  static Future<void> initialize() async {
    // Request notification permission (critical for Android 13+ and iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: User granted permission');
    }

    // Initialize Local Notifications for displaying foreground heads-up banners
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _routeByPayload(response.payload!);
        }
      },
    );

    // Create high-importance notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kissan_connect_channel',
      'Kissan Connect Notifications',
      description: 'High priority alerts for bookings and chats',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 2. Foreground notifications (FCM doesn't auto-display banners while app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data['route'] ?? '',
        );
      }
    });

    // 3. User taps notification when app was opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'];
      if (route != null) {
        _routeByPayload(route);
      }
    });

    // 4. App was terminated and launched directly by tapping the notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'];
      if (route != null) {
        // Slight delay to allow navigator widget to mount
        Future.delayed(const Duration(milliseconds: 600), () {
          _routeByPayload(route);
        });
      }
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Save the device's FCM token to the user's Firestore profile
  static Future<void> saveUserFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Listen for token refresh events
    _fcm.onTokenRefresh.listen((newToken) async {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(current.uid)
            .update({'fcmToken': newToken});
      }
    });
  }

  // Clear token on signout
  static Future<void> clearUserFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': FieldValue.delete()},
      );
    }
  }

  static void _routeByPayload(String route) {
    if (route.startsWith('chat:')) {
      final parts = route.replaceFirst('chat:', '').split('|');
      navigatorKey.currentState?.pushNamed(
        '/conversation',
        arguments: {
          'chatRoomId': parts[0],
          'peerName': parts.length > 1 ? parts[1] : 'Farmer',
        },
      );
    } else if (route == 'bookings') {
      navigatorKey.currentState?.pushNamed('/my_bookings');
    }
  }
}
