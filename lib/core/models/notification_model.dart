import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  bookingRequest,
  bookingAccepted,
  bookingRejected,
  general,
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedDocId; // Booking ID or Equipment ID
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedDocId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedDocId': relatedDocId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    NotificationType parsedType;
    switch (map['type']) {
      case 'bookingAccepted':
        parsedType = NotificationType.bookingAccepted;
        break;
      case 'bookingRejected':
        parsedType = NotificationType.bookingRejected;
        break;
      case 'bookingRequest':
        parsedType = NotificationType.bookingRequest;
        break;
      default:
        parsedType = NotificationType.general;
    }

    return NotificationModel(
      id: docId,
      recipientId: map['recipientId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: parsedType,
      relatedDocId: map['relatedDocId'],
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
