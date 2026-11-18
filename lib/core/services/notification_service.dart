import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kissan_connect/core/services/fcm_sender_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedDocId,
    String? customRoute,
    bool saveToInApp = true,
  }) async {
    // 1. Save in-app notification record in Firestore
    if (saveToInApp) {
      try {
        final docRef = _firestore.collection('notifications').doc();
        final notif = NotificationModel(
          id: docRef.id,
          recipientId: recipientId,
          title: title,
          body: body,
          type: type,
          relatedDocId: relatedDocId,
          isRead: false,
          createdAt: DateTime.now(),
        );

        await docRef.set(notif.toMap());
        log('Notification saved to Firestore: ${docRef.id}');
      } catch (e) {
        log('Firestore notification save error: $e');
      }
    }

    // 2. Resolve deep-link route based on NotificationType
    final String resolvedRoute = _resolveRoute(type, relatedDocId, customRoute);

    // 3. Dispatch push notification via FCM v1
    try {
      await FCMSenderService.sendPushNotification(
        recipientUserId: recipientId,
        title: title,
        body: body,
        route: resolvedRoute,
      );
    } catch (e) {
      log('FCM push dispatch error: $e');
    }
  }

  static String _resolveRoute(
    NotificationType type,
    String? relatedDocId,
    String? customRoute,
  ) {
    if (customRoute != null && customRoute.isNotEmpty) {
      return customRoute;
    }

    switch (type) {
      case NotificationType.bookingRequest:
        return 'booking_request:${relatedDocId ?? ''}';
      case NotificationType.bookingAccepted:
        return 'booking_confirmed:${relatedDocId ?? ''}';
      case NotificationType.bookingRejected:
        return 'booking_rejected:${relatedDocId ?? ''}';
      case NotificationType.chatMessage:
        return 'notifications';
      case NotificationType.general:
        return 'notifications';
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {}
  }

  // Mark all notifications for a user as read
  static Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {}
  }
}
