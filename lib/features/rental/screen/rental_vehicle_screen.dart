import 'package:flutter/material.dart';
import 'package:kissan_connect/features/rental/provider/equipment_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';

import '../widgets/equipment_card.dart';

class RentVehiclesScreen extends StatefulWidget {
  const RentVehiclesScreen({super.key});

  @override
  State<RentVehiclesScreen> createState() => _RentVehiclesScreenState();
}

class _RentVehiclesScreenState extends State<RentVehiclesScreen> {
  // Category list using strongly-typed model and asset image paths
  final List<FilterCategory> _categories = const [
    FilterCategory(name: 'All', assetImage: 'assets/icons/all.png'),
    FilterCategory(name: 'Tractor', assetImage: 'assets/icons/tractor.png'),
    FilterCategory(
      name: 'Cultivator',
      assetImage: 'assets/icons/cultivator.png',
    ),
    FilterCategory(
      name: 'Disc Plough',
      assetImage: 'assets/icons/disc_plough.png',
    ),
    FilterCategory(
      name: 'Disc Harrow',
      assetImage: 'assets/icons/disc_harrow.png',
    ),
    FilterCategory(
      name: 'Seed Drill',
      assetImage: 'assets/icons/seed_drill.png',
    ),
    FilterCategory(name: 'Rotavator', assetImage: 'assets/icons/rotavator.png'),
    FilterCategory(
      name: 'Paddy Transplanter',
      assetImage: 'assets/icons/paddy_transplanter.png',
    ),
    FilterCategory(name: 'Sprayer', assetImage: 'assets/icons/sprayer.png'),
    FilterCategory(name: 'Harvester', assetImage: 'assets/icons/harvester.png'),
    FilterCategory(name: 'Reaper', assetImage: 'assets/icons/reaper.png'),
    FilterCategory(name: 'Thresher', assetImage: 'assets/icons/thresher.png'),
    FilterCategory(
      name: 'Straw Reaper',
      assetImage: 'assets/icons/straw_reaper.png',
    ),
    FilterCategory(
      name: 'Laser Land Leveller',
      assetImage: 'assets/icons/laser_land_leveller.png',
    ),
    FilterCategory(
      name: 'Land Leveller',
      assetImage: 'assets/icons/land_leveller.png',
    ),
    FilterCategory(name: 'Trolley', assetImage: 'assets/icons/trolley.png'),
    FilterCategory(name: 'Grader', assetImage: 'assets/icons/grader.png'),
    FilterCategory(
      name: 'Tracter Sprayer',
      assetImage: 'assets/icons/tracter_sprayer.png',
    ),
    FilterCategory(
      name: 'Fertilizer Spreader',
      assetImage: 'assets/icons/fertilizer_spreader.png',
    ),
    FilterCategory(
      name: 'Potato Harvester',
      assetImage: 'assets/icons/potato_harvester.png',
    ),
    FilterCategory(
      name: 'Potato Seed Planter',
      assetImage: 'assets/icons/potato_seed_planter.png',
    ),
  ];

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

  // Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    await context.read<EquipmentProvider>().fetchEquipments();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
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
          // Search Box Bar
          Container(
            padding: const EdgeInsets.only(
              left: 18,
              right: 18,
              bottom: 10,
              top: 10,
            ),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: equipmentProvider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search vehicles or equipment...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // Horizontal Rounded-Edge Rectangle Asset Chips
          SizedBox(
            height: 45,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final categoryItem = _categories[index];
                final bool isSelected = equipmentProvider.selectedCategories
                    .contains(categoryItem.name);

                return GestureDetector(
                  onTap: () =>
                      equipmentProvider.toggleCategory(categoryItem.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF2E7D32).withOpacity(0.25)
                              : Colors.black.withOpacity(0.02),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category Asset Icon with Fallback
                        Image.asset(
                          categoryItem.assetImage,
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.agriculture_rounded,
                            size: 20,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          categoryItem.name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (isSelected && categoryItem.name != 'All') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Equipment List Feed wrapped in RefreshIndicator
          Expanded(
            child: equipmentProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: equipmentProvider.equipments.isEmpty
                        ? ListView(
                            // AlwaysScrollableScrollPhysics ensures the empty list can still be pulled down
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Text(
                                    'No vehicles found for selected filters.',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: 18,
                              right: 18,
                              bottom: 100,
                            ),
                            itemCount: equipmentProvider.equipments.length,
                            itemBuilder: (context, index) {
                              final item = equipmentProvider.equipments[index];
                              return EquipmentCard(
                                equipment: item,
                                onTap: () {
                                  // Detailed booking screen navigation
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class FilterCategory {
  final String name;
  final String assetImage;

  const FilterCategory({required this.name, required this.assetImage});
}
