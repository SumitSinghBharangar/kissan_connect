import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/equipment_model.dart';

class EquipmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EquipmentModel> _allEquipments = [];
  final Set<String> _selectedCategories = {'All'};
  String _searchQuery = '';
  bool _isLoading = false;

  // Map of equipmentId -> bookingStatus (e.g. 'pending', 'accepted', 'confirmed')
  Map<String, String> _userBookings = {};
  StreamSubscription? _bookingsSubscription;

  bool get isLoading => _isLoading;
  Set<String> get selectedCategories => _selectedCategories;
  Map<String, String> get userBookings => _userBookings;

  /// Check booking status for a specific equipment
  String? getBookingStatus(String equipmentId) => _userBookings[equipmentId];
  bool isPending(String equipmentId) => _userBookings[equipmentId] == 'pending';

  // Multi-chip & Search Filter
  List<EquipmentModel> get equipments {
    return _allEquipments.where((item) {
      // 1. Exclude if already accepted, confirmed, or in-progress
      final bookingStatus = _userBookings[item.id];
      if (bookingStatus == 'confirmed' ||
          bookingStatus == 'accepted' ||
          bookingStatus == 'in_progress') {
        return false;
      }

      // 2. Category matching
      final matchesCategory =
          _selectedCategories.contains('All') ||
          _selectedCategories.any(
            (cat) =>
                cat.toLowerCase() == item.category.name.toLowerCase() ||
                cat.toLowerCase() == item.typeLabel.toLowerCase(),
          );

      // 3. Search query matching
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

  /// Listen in real-time to current user's active bookings
  void listenToUserBookings() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    _bookingsSubscription?.cancel();
    _bookingsSubscription = _firestore
        .collection('bookings')
        .where('renterId', isEqualTo: currentUid)
        .where(
          'status',
          whereIn: ['pending', 'accepted', 'confirmed', 'in_progress'],
        )
        .snapshots()
        .listen((snapshot) {
          final Map<String, String> updatedMap = {};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final equipmentId = data['equipmentId'] as String?;
            final status = data['status'] as String? ?? 'pending';
            if (equipmentId != null) {
              updatedMap[equipmentId] = status;
            }
          }
          _userBookings = updatedMap;
          notifyListeners();
        });
  }

  Future<void> fetchEquipments() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    _isLoading = true;
    notifyListeners();

    // Start listening to bookings when fetching equipments
    listenToUserBookings();

    try {
      final snapshot = await _firestore
          .collection('equipments')
          .where('isAvailable', isEqualTo: true)
          .where('ownerId', isNotEqualTo: currentUid)
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

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }
}
