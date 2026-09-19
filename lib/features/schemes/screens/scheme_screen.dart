import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/features/schemes/screens/scheme_details_screen.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/scheme_model.dart';


class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Machinery Subsidy',
    'Direct Support',
    'Crop Insurance',
    'Credit & Loans',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kisan Yojana & Subsidies',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2E7D32),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  );
                },
              ),
            ),
          ),

          // Schemes Stream / List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('government_schemes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final docs = snapshot.data?.docs ?? [];
                List<SchemeModel> schemes = docs
                    .map((d) => SchemeModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                    .toList();

                if (schemes.isEmpty) {
                  schemes = _getDefaultSchemes();
                }

                final filtered = _selectedCategory == 'All'
                    ? schemes
                    : schemes.where((s) => s.category == _selectedCategory).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _SchemeCard(scheme: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<SchemeModel> _getDefaultSchemes() {
    return [
      SchemeModel(
        id: '1',
        title: 'Sub-Mission on Agricultural Mechanization (SMAM)',
        category: 'Machinery Subsidy',
        benefitSummary: '40% to 50% Subsidy on Tractors, Harvesters & Implements',
        description:
            'A central sector program designed to increase the reach of farm mechanization to small and marginal farmers with heavy subsidies on agricultural tools.',
        eligibility: [
          'Individual farmers with land records (Khatauni / Khasra)',
          'Preference given to Small & Marginal Farmers (SMF)',
          'Valid Aadhaar-linked bank account',
        ],
        requiredDocuments: [
          'Aadhaar Card',
          'Land Ownership Documents (Khatauni)',
          'Bank Passbook photocopy',
          'Caste Certificate (if applicable for enhanced subsidy)',
        ],
        officialPortalUrl: 'https://agrimachinery.nic.in',
      ),
      SchemeModel(
        id: '2',
        title: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
        category: 'Direct Support',
        benefitSummary: '₹6,000 Per Year in 3 Equal Installments',
        description:
            'Direct income support scheme transferring financial assistance straight into the bank accounts of all landholding farmer families.',
        eligibility: [
          'All landholding farmer families with cultivable land',
          'e-KYC completed on PM-KISAN portal',
        ],
        requiredDocuments: [
          'Aadhaar Card with mobile linkage',
          'Landholding certificate / Khasra',
          'Bank Account details with NPCI mapping',
        ],
        officialPortalUrl: 'https://pmkisan.gov.in',
      ),
      SchemeModel(
        id: '3',
        title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        category: 'Crop Insurance',
        benefitSummary: 'Comprehensive Risk Insurance against Natural Calamities',
        description:
            'Low premium crop insurance (1.5% - 2%) covering yield losses, localized calamities, post-harvest losses, and unseasonal weather damage.',
        eligibility: [
          'All farmers growing notified crops in notified areas',
          'Both loanee and non-loanee farmers eligible',
        ],
        requiredDocuments: [
          'Sowing Certificate / Patwari Report',
          'Aadhaar Card',
          'Land possession proof',
          'Bank passbook details',
        ],
        officialPortalUrl: 'https://pmfby.gov.in',
      ),
    ];
  }
}

class _SchemeCard extends StatelessWidget {
  final SchemeModel scheme;

  const _SchemeCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SchemeDetailScreen(scheme: scheme)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scheme.category,
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  scheme.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  scheme.benefitSummary,
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}