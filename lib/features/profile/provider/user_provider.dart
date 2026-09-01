import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Fetch or listen to user document
  Future<void> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, docId: doc.id);
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save or Update Profile
  Future<bool> saveUserProfile({
    required String name,
    required String village,
    required String district,
    required String state,
    String? profileImageUrl,
    String language = 'English',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedData = {
        'uid': user.uid,
        'name': name,
        'phone': user.phoneNumber ?? (_currentUser?.phone ?? ''),
        'village': village,
        'district': district,
        'state': state,
        'profileImage': profileImageUrl ?? _currentUser?.profileImage,
        'language': language,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updatedData, SetOptions(merge: true));

      await fetchUserProfile();
      return true;
    } catch (e) {
      debugPrint("Error updating profile: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
