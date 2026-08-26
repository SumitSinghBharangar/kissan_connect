import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/models/equipment_model.dart';

class EquipmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EquipmentModel> _allEquipments = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  // Filtered getter based on active category chip and search query
  List<EquipmentModel> get equipments {
    return _allEquipments.where((item) {
      final matchesCategory = _selectedCategory == 'All' ||
          item.category.name.toLowerCase() == _selectedCategory.toLowerCase() ||
          item.typeLabel.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSearch = item.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item.location.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Update selected category chip (All, Tractor, Harvester, etc.)
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Update search query text
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Fetch all available equipment from Firestore collection 'equipments'
  Future<void> fetchEquipments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('equipments')
          .where('isAvailable', isEqualTo: true)
          .get();

      _allEquipments = snapshot.docs
          .map((doc) => EquipmentModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching equipments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Real-time Stream alternative
  Stream<List<EquipmentModel>> streamEquipments() {
    return _firestore
        .collection('equipments')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      _allEquipments = snapshot.docs
          .map((doc) => EquipmentModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      notifyListeners();
      return _allEquipments;
    });
  }
}