import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/models/booking_model.dart';
import 'package:kissan_connect/core/models/equipment_model.dart';
import 'package:kissan_connect/core/models/notification_model.dart';
import 'package:kissan_connect/core/services/fcm_sender_service.dart';
import 'package:kissan_connect/core/services/notification_service.dart';

import 'package:kissan_connect/features/chat/screen/chat_screen.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:kissan_connect/features/rental/provider/equipment_provider.dart';
import 'package:kissan_connect/features/rental/widgets/booking_model_sheet.dart';
import 'package:provider/provider.dart';

class EquipmentDetailScreen extends StatelessWidget {
  final EquipmentModel equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  void _openBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingModalSheet(equipment: equipment),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to chat with the owner')),
      );
      return;
    }

    final currentUid = user.uid;
    final ownerUid = equipment.ownerId;

    if (currentUid == ownerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own equipment listing!')),
      );
      return;
    }

    try {
      // 1. Fallback to existing equipment/provider data if network document fetch fails
      String ownerName = 'Equipment Owner';

      try {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .get(const GetOptions(source: Source.serverAndCache));

        if (ownerDoc.exists && ownerDoc.data() != null) {
          ownerName = ownerDoc.data()!['name'] ?? ownerName;
        }
      } catch (_) {
        // Use fallback owner name without crashing if user profile doc is slow or offline
      }

      final currentUserName =
          context.read<UserProvider>().currentUser?.name ?? 'Farmer';

      // 2. Deterministic room ID
      final sortedIds = [currentUid, ownerUid]..sort();
      final roomId = '${sortedIds[0]}_${sortedIds[1]}';

      final roomRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId);

      // 3. Use SetOptions(merge: true) instead of get() to avoid blocking if offline
      await roomRef.set({
        'participants': [currentUid, ownerUid],
        'participantNames': {currentUid: currentUserName, ownerUid: ownerName},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      // 4. Navigate
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ConversationScreen(chatRoomId: roomId, peerName: ownerName),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = context.select<EquipmentProvider, bool>(
      (provider) => provider.isPending(equipment.id),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        slivers: [
          // 1. Collapsible App Bar with Equipment Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF388E3C),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'equipment_image_${equipment.id}',
                    child: Image.network(
                      equipment.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(
                          Icons.agriculture,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                          Colors.black45,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Equipment Specifications & Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              equipment.typeLabel,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFFFB300),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              equipment.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Feature Spec Cards
                  Row(
                    children: [
                      _buildSpecTile(
                        Icons.payments_outlined,
                        'Rate',
                        '₹${equipment.ratePerHour.toInt()}/hr',
                      ),
                      const SizedBox(width: 10),
                      _buildSpecTile(
                        Icons.location_on_outlined,
                        'Location',
                        equipment.location,
                      ),
                      const SizedBox(width: 10),
                      _buildSpecTile(
                        Icons.verified_outlined,
                        'Availability',
                        equipment.isAvailable ? 'Ready' : 'In Use',
                        accentColor: equipment.isAvailable
                            ? const Color(0xFF2E7D32)
                            : Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Owner / Host Card
                  const Text(
                    'Machinery Owner',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _buildOwnerCard(equipment.ownerId),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Overview & Condition',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (equipment.description != null &&
                            equipment.description!.trim().isNotEmpty)
                        ? equipment.description!
                        : 'Well-maintained machinery suitable for cultivation, ploughing, and harvest operations. Fuel and experienced driver options can be discussed during booking.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Persistent Booking Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${equipment.ratePerHour.toInt()} / hr',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chat_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _openChat(context),
                ),
              ),
              const SizedBox(width: 12),
              if (!isPending)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: equipment.isAvailable
                          ? () => _openBookingSheet(context)
                          : null,
                      child: Text(
                        equipment.isAvailable
                            ? 'Book Machine'
                            : 'Currently Rented',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isPending)
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Requested',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecTile(
    IconData icon,
    String label,
    String value, {
    Color? accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: accentColor ?? AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: accentColor ?? AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(String ownerId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
      builder: (context, snapshot) {
        String ownerName = 'Verified Farmer';
        String ownerPhone = 'Contact via Booking';
        String? ownerImage;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          ownerName = data?['name'] ?? ownerName;
          ownerPhone = data?['phone'] ?? ownerPhone;
          ownerImage = data?['profileImage'];
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: ownerImage != null && ownerImage.isNotEmpty
                    ? NetworkImage(ownerImage)
                    : null,
                child: ownerImage == null
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      ownerPhone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const IconButton(
                  icon: Icon(
                    Icons.verified,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
