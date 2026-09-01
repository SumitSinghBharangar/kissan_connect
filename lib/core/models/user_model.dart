import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String name;
  String phone;
  String? profileImage;
  String village;
  String district;
  String state;
  String language;
  bool isProfileComplete;
  List<String> favoriteEquipmentIds;
  DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.profileImage,
    required this.village,
    required this.district,
    required this.state,
    this.language = 'English',
    this.isProfileComplete = false,
    this.favoriteEquipmentIds = const [],
    required this.createdAt,
  });

  // Display helper for full location
  String get fullAddress {
    final parts = [
      village,
      district,
      state,
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Address not set' : parts.join(', ');
  }

  // Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'village': village,
      'district': district,
      'state': state,
      'language': language,
      'isProfileComplete': isProfileComplete,
      'favoriteEquipmentIds': favoriteEquipmentIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // JSON Map
  Map<String, dynamic> toJsonMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'village': village,
      'district': district,
      'state': state,
      'language': language,
      'isProfileComplete': isProfileComplete,
      'favoriteEquipmentIds': favoriteEquipmentIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Firestore -> Model
  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserModel(
      uid: docId ?? (map['uid'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      profileImage: map['profileImage'] as String?,
      village: map['village'] as String? ?? '',
      district: map['district'] as String? ?? '',
      state: map['state'] as String? ?? '',
      language: map['language'] as String? ?? 'English',
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      favoriteEquipmentIds: List<String>.from(
        map['favoriteEquipmentIds'] ?? [],
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // JSON -> Model
  factory UserModel.fromJson(String source) {
    final map = json.decode(source);
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      phone: map['phone'],
      profileImage: map['profileImage'],
      village: map['village'],
      district: map['district'],
      state: map['state'],
      language: map['language'] ?? 'English',
      isProfileComplete: map['isProfileComplete'] ?? false,
      favoriteEquipmentIds: List<String>.from(
        map['favoriteEquipmentIds'] ?? [],
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toJsonMap());
}
