import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/features/rental/provider/equipment_provider.dart';
import 'package:kissan_connect/features/rental/widgets/equipment_card.dart';
import 'package:provider/provider.dart';


class RentVehiclesScreen extends StatefulWidget {
  const RentVehiclesScreen({super.key});

  @override
  State<RentVehiclesScreen> createState() => _RentVehiclesScreenState();
}

class _RentVehiclesScreenState extends State<RentVehiclesScreen> {
  final List<String> _categories = ['All', 'Tractor', 'Harvester', 'Plough', 'Trailer', 'Rotavator'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EquipmentProvider>().fetchEquipments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      // Green App Bar Header
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Rent Vehicles',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box Container
          Container(
            color: const Color(0xFF388E3C),
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: equipmentProvider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search vehicles or equipment...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal Category Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = equipmentProvider.selectedCategory == category;

                return GestureDetector(
                  onTap: () => equipmentProvider.setCategory(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF388E3C) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Equipment List Feed
          Expanded(
            child: equipmentProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : equipmentProvider.equipments.isEmpty
                    ? Center(
                        child: Text(
                          'No vehicles available in this category.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 100),
                        itemCount: equipmentProvider.equipments.length,
                        itemBuilder: (context, index) {
                          final item = equipmentProvider.equipments[index];
                          return EquipmentCard(
                            equipment: item,
                            onTap: () {
                              // Navigate to dynamic booking page
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}