import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  // Sends an in-app notification to any user
  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedDocId,
  }) async {
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
  }

  // Mark all notifications for a user as read
  static Future<void> markAllAsRead(String userId) async {
    final unread = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
