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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      final String route = message.data['route'] ?? '';

      // Suppress foreground popup if user is already viewing this exact chat room
      if (route.startsWith('chat:')) {
        final incomingChatId = route.replaceFirst('chat:', '').split('|').first;
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .get();
          if (userDoc.data()?['activeChatId'] == incomingChatId) {
            return;
          }
        }
      }

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
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: route,
      );
    });

    // 3. User taps notification when app was opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'];
      if (route != null && route.isNotEmpty) {
        _routeByPayload(route);
      }
    });

    // 4. App was terminated and launched directly by tapping the notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'];
      if (route != null && route.isNotEmpty) {
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
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      }
    });
  }

  // Clear token and activeChatId on signout
  static Future<void> clearUserFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': FieldValue.delete(),
        'activeChatId': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  // Unified route dispatcher for all notification types
  static void _routeByPayload(String route) {
    final navigator = navigatorKey.currentState;
    if (navigator == null || route.isEmpty) return;

    // 1. Chat Messages -> Format: 'chat:chatRoomId|senderUid|senderName' (or 'chat:chatRoomId|senderName')
    if (route.startsWith('chat:')) {
      final parts = route.replaceFirst('chat:', '').split('|');
      final String chatRoomId = parts[0];
      final String recipientUid = parts.length >= 3 ? parts[1] : '';
      final String peerName = parts.length >= 3
          ? parts[2]
          : (parts.length == 2 ? parts[1] : 'Farmer');

      navigator.pushNamed(
        '/conversation',
        arguments: {
          'chatRoomId': chatRoomId,
          'recipientUid': recipientUid,
          'peerName': peerName,
        },
      );
      return;
    }

    // 2. Incoming Rental Request (Owner View) -> Format: 'booking_request:bookingId'
    if (route.startsWith('booking_request:')) {
      final bookingId = route.replaceFirst('booking_request:', '');
      navigator.pushNamed(
        '/my_bookings',
        arguments: {
          'initialTab': 1, // Owner incoming requests tab
          'bookingId': bookingId,
        },
      );
      return;
    }

    // 3. Booking Approved / Confirmed (Renter View) -> Format: 'booking_confirmed:bookingId'
    if (route.startsWith('booking_confirmed:')) {
      final bookingId = route.replaceFirst('booking_confirmed:', '');
      navigator.pushNamed(
        '/my_bookings',
        arguments: {
          'initialTab': 0, // Renter bookings tab
          'bookingId': bookingId,
        },
      );
      return;
    }

    // 4. Booking Rejected / Cancelled -> Format: 'booking_rejected:bookingId'
    if (route.startsWith('booking_rejected:') || route == 'bookings') {
      navigator.pushNamed('/my_bookings');
      return;
    }

    // 5. Fallback -> In-App Notifications Screen
    navigator.pushNamed('/notifications');
  }
}