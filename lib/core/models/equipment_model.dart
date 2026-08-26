import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kissan_connect/core/constants/app_enums.dart';

extension EquipmentCategoryExt on EquipmentCategory {
  String get name {
    switch (this) {
      case EquipmentCategory.tractor:
        return 'Tractor';
      case EquipmentCategory.harvester:
        return 'Harvester';
      case EquipmentCategory.plough:
        return 'Plough';
      case EquipmentCategory.trailer:
        return 'Trailer';
      case EquipmentCategory.rotavator:
        return 'Rotavator';
      case EquipmentCategory.sprayer:
        return 'Sprayer';
      case EquipmentCategory.other:
        return 'Other';
    }
  }

  static EquipmentCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'tractor':
        return EquipmentCategory.tractor;
      case 'harvester':
        return EquipmentCategory.harvester;
      case 'plough':
        return EquipmentCategory.plough;
      case 'trailer':
      case 'trolley':
        return EquipmentCategory.trailer;
      case 'rotavator':
        return EquipmentCategory.rotavator;
      case 'sprayer':
        return EquipmentCategory.sprayer;
      default:
        return EquipmentCategory.other;
    }
  }
}

class EquipmentModel {
  String id;
  String name;
  EquipmentCategory category;
  String typeLabel; // e.g. "Tractor", "Equipment", "Trailer"
  num ratePerHour;
  String location;
  num rating;
  String imageUrl;
  bool isAvailable;
  String ownerId;
  String? description;
  DateTime createdAt;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.typeLabel,
    required this.ratePerHour,
    required this.location,
    required this.rating,
    required this.imageUrl,
    required this.isAvailable,
    required this.ownerId,
    this.description,
    required this.createdAt,
  });

  // 🔥 Firestore Map (uses Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'typeLabel': typeLabel,
      'ratePerHour': ratePerHour,
      'location': location,
      'rating': rating,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // 🔥 JSON Map (NO Timestamp here)
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'typeLabel': typeLabel,
      'ratePerHour': ratePerHour,
      'location': location,
      'rating': rating,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 🔥 Firestore → Model
  factory EquipmentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return EquipmentModel(
      id: docId ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      category: EquipmentCategoryExt.fromString(
        map['category'] as String? ?? 'other',
      ),
      typeLabel: map['typeLabel'] as String? ?? 'Equipment',
      ratePerHour: map['ratePerHour'] as num? ?? 0,
      location: map['location'] as String? ?? '',
      rating: map['rating'] as num? ?? 5.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      isAvailable: map['isAvailable'] as bool? ?? true,
      ownerId: map['ownerId'] as String? ?? '',
      description: map['description'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // 🔥 JSON → Model
  factory EquipmentModel.fromJson(String source) {
    final map = json.decode(source);
    return EquipmentModel(
      id: map['id'],
      name: map['name'],
      category: EquipmentCategoryExt.fromString(map['category']),
      typeLabel: map['typeLabel'],
      ratePerHour: map['ratePerHour'],
      location: map['location'],
      rating: map['rating'],
      imageUrl: map['imageUrl'],
      isAvailable: map['isAvailable'],
      ownerId: map['ownerId'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // 🔥 Model → JSON String
  String toJson() => json.encode(toJsonMap());
}
