import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/models/equipment_model.dart';

class EquipmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EquipmentModel> _allEquipments = [];
  final Set<String> _selectedCategories = {'All'};
  String _searchQuery = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Set<String> get selectedCategories => _selectedCategories;

  // Multi-chip & Search Filter
  List<EquipmentModel> get equipments {
    return _allEquipments.where((item) {
      final matchesCategory =
          _selectedCategories.contains('All') ||
          _selectedCategories.any(
            (cat) =>
                cat.toLowerCase() == item.category.name.toLowerCase() ||
                cat.toLowerCase() == item.typeLabel.toLowerCase(),
          );

      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.location.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Toggle Chip Selection Logic
  void toggleCategory(String category) {
    if (category == 'All') {
      _selectedCategories.clear();
      _selectedCategories.add('All');
    } else {
      _selectedCategories.remove('All');
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        if (_selectedCategories.isEmpty) {
          _selectedCategories.add('All');
        }
      } else {
        _selectedCategories.add(category);
      }
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

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
}
