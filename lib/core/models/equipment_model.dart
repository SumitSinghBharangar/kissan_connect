import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kissan_connect/core/constants/app_enums.dart';

extension EquipmentCategoryExt on EquipmentCategory {
  String get name {
    switch (this) {
      case EquipmentCategory.tractor:
        return 'Tractor';

      case EquipmentCategory.cultivator:
        return 'Cultivator';

      case EquipmentCategory.disc_plough:
        return 'Disc Plough';

      case EquipmentCategory.disc_harrow:
        return 'Disc Harrow';

      case EquipmentCategory.seed_drill:
        return 'Seed Drill';

      case EquipmentCategory.rotavator:
        return 'Rotavator';

      case EquipmentCategory.paddy_transplanter:
        return 'Paddy Transplanter';

      case EquipmentCategory.sprayer:
        return 'Sprayer';

      case EquipmentCategory.harvester:
        return 'Harvester';

      case EquipmentCategory.reaper:
        return 'Reaper';

      case EquipmentCategory.thresher:
        return 'Thresher';

      case EquipmentCategory.straw_reaper:
        return 'Straw Reaper';

      case EquipmentCategory.laser_land_leveller:
        return 'Laser Land Leveller';

      case EquipmentCategory.land_leveller:
        return 'Land Leveller';

      case EquipmentCategory.trolley:
        return 'Trolley';

      case EquipmentCategory.grader:
        return 'Grader';

      case EquipmentCategory.tracter_sprayer:
        return 'Tractor Sprayer';

      case EquipmentCategory.fertilizer_spreader:
        return 'Fertilizer Spreader';

      case EquipmentCategory.potato_harvester:
        return 'Potato Harvester';

      case EquipmentCategory.potato_seed_planter:
        return 'Potato Seed Planter';

      case EquipmentCategory.other:
        return 'Other';
    }
  }

  static EquipmentCategory fromString(String category) {
    switch (category.toLowerCase().trim()) {
      case 'tractor':
        return EquipmentCategory.tractor;

      case 'cultivator':
        return EquipmentCategory.cultivator;

      case 'disc_plough':
      case 'disc plough':
        return EquipmentCategory.disc_plough;

      case 'disc_harrow':
      case 'disc harrow':
        return EquipmentCategory.disc_harrow;

      case 'seed_drill':
      case 'seed drill':
        return EquipmentCategory.seed_drill;

      case 'rotavator':
        return EquipmentCategory.rotavator;

      case 'paddy_transplanter':
      case 'paddy transplanter':
        return EquipmentCategory.paddy_transplanter;

      case 'sprayer':
        return EquipmentCategory.sprayer;

      case 'harvester':
        return EquipmentCategory.harvester;

      case 'reaper':
        return EquipmentCategory.reaper;

      case 'thresher':
        return EquipmentCategory.thresher;

      case 'straw_reaper':
      case 'straw reaper':
        return EquipmentCategory.straw_reaper;

      case 'laser_land_leveller':
      case 'laser land leveller':
        return EquipmentCategory.laser_land_leveller;

      case 'land_leveller':
      case 'land leveller':
        return EquipmentCategory.land_leveller;

      case 'trolley':
        return EquipmentCategory.trolley;

      case 'grader':
        return EquipmentCategory.grader;

      case 'tracter_sprayer':
      case 'tractor_sprayer':
      case 'tractor sprayer':
        return EquipmentCategory.tracter_sprayer;

      case 'fertilizer_spreader':
      case 'fertilizer spreader':
        return EquipmentCategory.fertilizer_spreader;

      case 'potato_harvester':
      case 'potato harvester':
        return EquipmentCategory.potato_harvester;

      case 'potato_seed_planter':
      case 'potato seed planter':
        return EquipmentCategory.potato_seed_planter;

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
