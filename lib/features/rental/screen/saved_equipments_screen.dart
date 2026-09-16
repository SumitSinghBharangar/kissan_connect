import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/models/equipment_model.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:kissan_connect/features/rental/screen/equipment_detail_screen.dart';
import 'package:kissan_connect/features/rental/widgets/equipment_card.dart';
import 'package:provider/provider.dart';

class SavedEquipmentsScreen extends StatelessWidget {
  const SavedEquipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final favoriteIds = userProvider.currentUser?.favoriteEquipmentIds ?? [];

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
          'Saved Machinery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: favoriteIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No saved machinery yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bookmark tractors and tools to rent later',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipments')
                  .where(
                    FieldPath.documentId,
                    whereIn: favoriteIds.take(10).toList(),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Saved items no longer exist.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = EquipmentModel.fromMap(
                      docs[index].data() as Map<String, dynamic>,
                      docId: docs[index].id,
                    );
                    return EquipmentCard(
                      equipment: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EquipmentDetailScreen(equipment: item),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
