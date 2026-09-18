import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/features/rental/screen/my_bookings_screen.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => NotificationService.markAllAsRead(uid),
            child: const Text(
              'Read All',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = NotificationModel.fromMap(
                docs[index].data() as Map<String, dynamic>,
                docs[index].id,
              );

              return _NotificationCard(notif: notif);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notif;

  const _NotificationCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case NotificationType.bookingAccepted:
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF2E7D32);
        break;
      case NotificationType.bookingRejected:
        icon = Icons.cancel_rounded;
        iconColor = Colors.red;
        break;
      case NotificationType.bookingRequest:
        icon = Icons.agriculture_rounded;
        iconColor = Colors.amber.shade800;
        break;
      default:
        icon = Icons.info_rounded;
        iconColor = const Color(0xFF0288D1);
    }

    return Container(
      decoration: BoxDecoration(
        color: notif.isRead
            ? Colors.white
            : const Color(0xFFE8F5E9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notif.isRead ? Colors.grey.shade200 : const Color(0xFF81C784),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            notif.body,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ),
        onTap: () {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(notif.id)
              .update({'isRead': true});
          if (notif.relatedDocId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            );
          }
        },
      ),
    );
  }
}
