import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/models/mandi_price_model.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:provider/provider.dart';

class MandiScreen extends StatefulWidget {
  const MandiScreen({super.key});

  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDistrict = 'All';
  String _searchQuery = '';

  final List<String> _districts = [
    'All',
    'Mathura',
    'Agra',
    'Aligarh',
    'Hathras',
    'Bharatpur',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser;
    if (user != null &&
        user.district.isNotEmpty &&
        _districts.contains(user.district)) {
      _selectedDistrict = user.district;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Mandi Market Rates',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search commodity (e.g. Wheat, Potato)...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // District Filter Chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _districts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final dist = _districts[index];
                      final isSelected = _selectedDistrict == dist;
                      return ChoiceChip(
                        label: Text(dist),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2E7D32),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _selectedDistrict = dist);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Commodity Prices List Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mandi_rates')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // If collection doesn't exist or is empty, provide fallback demo records
                final docs = snapshot.data?.docs ?? [];
                List<MandiPriceModel> rates = docs.map((d) {
                  return MandiPriceModel.fromMap(
                    d.data() as Map<String, dynamic>,
                    docId: d.id,
                  );
                }).toList();

                if (rates.isEmpty) {
                  rates = _getDemoRates();
                }

                // Apply dynamic filters
                final filtered = rates.where((item) {
                  final matchDistrict =
                      _selectedDistrict == 'All' ||
                      item.district.toLowerCase() ==
                          _selectedDistrict.toLowerCase();
                  final matchSearch =
                      _searchQuery.isEmpty ||
                      item.commodity.toLowerCase().contains(_searchQuery) ||
                      item.mandi.toLowerCase().contains(_searchQuery);
                  return matchDistrict && matchSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No rates found matching criteria.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rate = filtered[index];
                    return _MandiPriceCard(rate: rate);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MandiPriceModel> _getDemoRates() {
    return [
      MandiPriceModel(
        id: '1',
        commodity: 'Wheat (गेहूं)',
        variety: 'Dara',
        mandi: 'Mathura Mandi',
        district: 'Mathura',
        state: 'Uttar Pradesh',
        minPrice: 2275,
        maxPrice: 2450,
        modalPrice: 2380,
        date: DateTime.now(),
      ),
      MandiPriceModel(
        id: '2',
        commodity: 'Mustard (सरसों)',
        variety: 'Black Mustard',
        mandi: 'Kosi Kalan Mandi',
        district: 'Mathura',
        state: 'Uttar Pradesh',
        minPrice: 4950,
        maxPrice: 5350,
        modalPrice: 5200,
        date: DateTime.now(),
      ),
      MandiPriceModel(
        id: '3',
        commodity: 'Potato (आलू)',
        variety: 'Desi Red',
        mandi: 'Fatehabad Mandi',
        district: 'Agra',
        state: 'Uttar Pradesh',
        minPrice: 1050,
        maxPrice: 1300,
        modalPrice: 1220,
        date: DateTime.now(),
      ),
      MandiPriceModel(
        id: '4',
        commodity: 'Paddy (धान)',
        variety: 'Basmati 1121',
        mandi: 'Aligarh Mandi',
        district: 'Aligarh',
        state: 'Uttar Pradesh',
        minPrice: 3800,
        maxPrice: 4250,
        modalPrice: 4100,
        date: DateTime.now(),
      ),
    ];
  }
}

class _MandiPriceCard extends StatelessWidget {
  final MandiPriceModel rate;

  const _MandiPriceCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  rate.commodity,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rate.variety,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${rate.mandi}, ${rate.district}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _priceColumn('Min Price', '₹${rate.minPrice}'),
              _priceColumn('Max Price', '₹${rate.maxPrice}'),
              _priceColumn(
                'Modal (Avg)',
                '₹${rate.modalPrice}',
                isHighlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceColumn(String title, String price, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isHighlight ? 15 : 13,
            color: isHighlight
                ? const Color(0xFF2E7D32)
                : AppColors.textPrimary,
          ),
        ),
        Text(
          '/ Quintal',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
