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
  }) async {
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
      log("data saved successfully");
    } catch (e) {
      log('firestore notification save error');
    }

    final String resolvedRoute =
        customRoute ??
        ((type == NotificationType.bookingRequest ||
                type == NotificationType.bookingAccepted)
            ? 'bookings'
            : 'notifications');

    await FCMSenderService.sendPushNotification(
      recipientUserId: recipientId,
      title: title,
      body: body,
      route: resolvedRoute,
    );
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
