import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final String lastSenderId;
  final DateTime updatedAt;

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatRoomModel(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastSenderId: map['lastSenderId'] ?? '',
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
