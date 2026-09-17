import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

extension BookingStatusExt on BookingStatus {
  String get name {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'inProgress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  static BookingStatus fromString(String status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'inProgress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
}

class BookingModel {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String equipmentImageUrl;
  final String ownerId;
  final String renterId;
  final String ownerName;
  final String ownerPhone;
  final String renterName;
  final String renterPhone;
  final DateTime bookingDate;
  final int totalHours;
  final num ratePerHour;
  final num totalAmount;
  final BookingStatus status;
  final String? deliveryNotes;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentImageUrl,
    required this.ownerId,

    required this.renterId,
    required this.renterName,
    required this.renterPhone,
    required this.ownerName,
    required this.ownerPhone,
    required this.bookingDate,
    required this.totalHours,
    required this.ratePerHour,
    required this.totalAmount,
    this.status = BookingStatus.pending,
    this.deliveryNotes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentImageUrl': equipmentImageUrl,
      'ownerId': ownerId,
      'renterId': renterId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'renterName': renterName,
      'renterPhone': renterPhone,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'totalHours': totalHours,
      'ratePerHour': ratePerHour,
      'totalAmount': totalAmount,
      'status': status.name,
      'deliveryNotes': deliveryNotes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return BookingModel(
      id: docId ?? (map['id'] as String? ?? ''),
      equipmentId: map['equipmentId'] as String? ?? '',
      equipmentName: map['equipmentName'] as String? ?? '',
      equipmentImageUrl: map['equipmentImageUrl'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerPhone: map['ownerPhone'] as String? ?? '',
      renterId: map['renterId'] as String? ?? '',
      renterName: map['renterName'] as String? ?? '',
      renterPhone: map['renterPhone'] as String? ?? '',
      bookingDate: map['bookingDate'] != null
          ? (map['bookingDate'] as Timestamp).toDate()
          : DateTime.now(),
      totalHours: map['totalHours'] as int? ?? 1,
      ratePerHour: map['ratePerHour'] as num? ?? 0,
      totalAmount: map['totalAmount'] as num? ?? 0,
      status: BookingStatusExt.fromString(
        map['status'] as String? ?? 'pending',
      ),
      deliveryNotes: map['deliveryNotes'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
}
