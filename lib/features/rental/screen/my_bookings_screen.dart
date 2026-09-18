import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/models/booking_model.dart';
import 'package:kissan_connect/core/models/notification_model.dart';
import 'package:kissan_connect/core/services/notification_service.dart';
import 'package:kissan_connect/core/utils/contact_helper.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            'Rental Activities',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'My Rentals'),
              Tab(text: 'Received Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Bookings placed by current user as a renter
            _BookingsList(
              query: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('renterId', isEqualTo: currentUserId)
                  .orderBy('createdAt', descending: true),
              isOwnerView: false,
            ),

            // Tab 2: Booking requests received by current user as machinery owner
            _BookingsList(
              query: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('ownerId', isEqualTo: currentUserId)
                  .orderBy('createdAt', descending: true),
              isOwnerView: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final Query query;
  final bool isOwnerView;

  const _BookingsList({required this.query, required this.isOwnerView});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading bookings: ${snapshot.error}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  isOwnerView
                      ? 'No incoming requests yet'
                      : 'No machinery booked yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final booking = BookingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            );
            return _BookingCard(booking: booking, isOwnerView: isOwnerView);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isOwnerView;

  const _BookingCard({required this.booking, required this.isOwnerView});

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFF2E7D32);
      case BookingStatus.inProgress:
        return const Color(0xFF0288D1);
      case BookingStatus.completed:
        return Colors.blueGrey;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.pending:
      default:
        return const Color(0xFFF57C00);
    }
  }

  Future<void> _handleContact(BuildContext context) async {
    String targetPhone = isOwnerView ? booking.renterPhone : booking.ownerPhone;
    String targetName = isOwnerView ? booking.renterName : booking.ownerName;

    // Fallback for older booking docs without ownerPhone
    if (targetPhone.isEmpty) {
      final targetUid = isOwnerView ? booking.renterId : booking.ownerId;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .get();
      if (doc.exists && doc.data() != null) {
        targetPhone = doc.data()!['phone'] ?? '';
        targetName = doc.data()!['name'] ?? targetName;
      }
    }

    if (targetPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact number is not available for this user'),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Bottom sheet with direct Call and WhatsApp actions
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact $targetName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(targetPhone, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Color(0xFF2E7D32)),
                ),
                title: const Text(
                  'Direct Phone Call',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactHelper.makePhoneCall(context, targetPhone);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF25D366),
                  ),
                ),
                title: const Text(
                  'Message on WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactHelper.openWhatsApp(
                    context,
                    targetPhone,
                    message:
                        'Hello $targetName, regarding booking for ${booking.equipmentName} on Kissan Connect...',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    BookingStatus newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update(
        {'status': newStatus.name, 'updatedAt': FieldValue.serverTimestamp()},
      );
      await NotificationService.sendNotification(
        recipientId: booking.renterId,
        title: newStatus == BookingStatus.confirmed
            ? 'Booking Confirmed! 🚜'
            : 'Booking Declined',
        body: newStatus == BookingStatus.confirmed
            ? 'Your request for ${booking.equipmentName} was accepted by the owner.'
            : 'Your request for ${booking.equipmentName} could not be accepted.',
        type: newStatus == BookingStatus.confirmed
            ? NotificationType.bookingAccepted
            : NotificationType.bookingRejected,
        relatedDocId: docId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Equipment & Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    booking.equipmentImageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.agriculture,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.equipmentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOwnerView
                            ? 'Rented by: ${booking.renterName}'
                            : 'Duration: ${booking.totalHours} hrs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Price & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '₹${booking.totalAmount.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                if (isOwnerView && booking.status == BookingStatus.pending) ...[
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _updateStatus(
                          context,
                          booking.id,
                          BookingStatus.cancelled,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _updateStatus(
                          context,
                          booking.id,
                          BookingStatus.confirmed,
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: () => _handleContact(context),
                    icon: const Icon(
                      Icons.call_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      isOwnerView ? 'Call Renter' : 'Contact Owner',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
