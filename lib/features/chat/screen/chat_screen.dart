import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_model.dart';

class ConversationScreen extends StatefulWidget {
  final String chatRoomId;
  final String peerName;

  const ConversationScreen({
    super.key,
    required this.chatRoomId,
    required this.peerName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final roomRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId);
    final messagesRef = roomRef.collection('messages');

    final batch = FirebaseFirestore.instance.batch();

    // 1. Add new message
    final newMsgDoc = messagesRef.doc();
    batch.set(newMsgDoc, {
      'senderId': _currentUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update parent chat room snippet
    batch.update(roomRef, {
      'lastMessage': text,
      'lastSenderId': _currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.peerName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to start the discussion!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = ChatMessageModel.fromMap(
                      docs[index].data() as Map<String, dynamic>,
                      docs[index].id,
                    );
                    final bool isMe = msg.senderId == _currentUid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF2E7D32) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isMe ? 14 : 2),
                            bottomRight: Radius.circular(isMe ? 2 : 14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
