import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kissan_connect/core/services/fcm_sender_service.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_model.dart';

class ConversationScreen extends StatefulWidget {
  final String chatRoomId;
  final String peerName;
  final String recipientUid;

  const ConversationScreen({
    super.key,
    required this.chatRoomId,
    required this.recipientUid,
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

    final senderName =
        context.read<UserProvider>().currentUser?.name ?? 'Farmer';

    final roomRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId);
    final messagesRef = roomRef.collection('messages');

    final batch = FirebaseFirestore.instance.batch();

    // 1. Add new message with all model fields
    final newMsgDoc = messagesRef.doc();
    batch.set(newMsgDoc, {
      'id': newMsgDoc.id,
      'senderId': _currentUid,
      'senderName': senderName,
      'recipientId': widget.recipientUid,
      'text': text,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp':
          FieldValue.serverTimestamp(), // Kept in case your StreamBuilder orders by 'timestamp'
    });

    // 2. Update parent chat room snippet
    batch.update(roomRef, {
      'lastMessage': text,
      'lastSenderId': _currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // 3. Trigger push notification to the recipient
    await FCMSenderService.sendPushNotification(
      recipientUserId: widget.recipientUid,
      title: '💬 $senderName',
      body: text,
      route: 'chat:${widget.chatRoomId}|$senderName',
    );
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _markIncomingMessagesAsRead(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    bool hasUnread = false;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['senderId'] != _currentUid && data['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
        hasUnread = true;
      }
    }

    if (hasUnread) {
      await batch.commit();
    }
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteMessage({
    required String messageId,
    required bool isLastMessage,
  }) async {
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId);

      // Delete the specific message document
      await chatRef.collection('messages').doc(messageId).delete();

      // Update the parent chat room's lastMessage preview if needed
      if (isLastMessage) {
        final remaining = await chatRef
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (remaining.docs.isNotEmpty) {
          final latestData = remaining.docs.first.data();
          await chatRef.update({
            'lastMessage': latestData['text'] ?? '',
            'updatedAt':
                latestData['createdAt'] ?? FieldValue.serverTimestamp(),
          });
        } else {
          await chatRef.update({'lastMessage': 'Message deleted'});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
      }
    }
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
                    final bool isLastMessage = index == 0;

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(
                        messageId: msg.id,
                        text: msg.text,
                        isMe: isMe,
                        isLastMessage: isLastMessage,
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.fromLTRB(14, 10, 12, 6),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF2E7D32)
                                : Colors.white,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Message Text
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Timestamp + Read Receipt Ticks
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatMessageTime(msg.createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white.withOpacity(0.75)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all_rounded,
                                      size: 14,
                                      color: msg.isRead
                                          ? const Color(
                                              0xFF81D4FA,
                                            ) // Light blue when read
                                          : Colors.white.withOpacity(
                                              0.65,
                                            ), // Muted when sent
                                    ),
                                  ],
                                ],
                              ),
                            ],
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

  void _showMessageOptions({
    required String messageId,
    required String text,
    required bool isMe,
    required bool isLastMessage,
  }) {
    // Subtle haptic feedback on long press
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Copy Option (Available for all messages)
                ListTile(
                  leading: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF2E7D32),
                  ),
                  title: const Text(
                    'Copy Message',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _copyMessage(text);
                  },
                ),

                // Delete Option (Only shown if the current user sent this message)
                if (isMe)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete Message',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmDeleteDialog(
                        messageId: messageId,
                        isLastMessage: isLastMessage,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteDialog({
    required String messageId,
    required bool isLastMessage,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text(
          'This message will be permanently removed for everyone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _deleteMessage(
                messageId: messageId,
                isLastMessage: isLastMessage,
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
