import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/models/booking_model.dart';
import 'package:kissan_connect/core/models/equipment_model.dart';
import 'package:kissan_connect/core/models/notification_model.dart';
import 'package:kissan_connect/core/services/fcm_sender_service.dart';
import 'package:kissan_connect/core/services/notification_service.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:provider/provider.dart';

class BookingModalSheet extends StatefulWidget {
  final EquipmentModel equipment;

  const BookingModalSheet({super.key, required this.equipment});

  @override
  State<BookingModalSheet> createState() => _BookingModalSheetState();
}

class _BookingModalSheetState extends State<BookingModalSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedHours = 4;
  final TextEditingController _notesController = TextEditingController();
  bool _isBooking = false;

  num get _totalEstimate => widget.equipment.ratePerHour * _selectedHours;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    final userProvider = context.read<UserProvider>();
    final currentUserData = userProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place a booking')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.equipment.ownerId)
          .get();

      String ownerName = 'Equipment Owner';
      String ownerPhone = '';

      if (ownerDoc.exists && ownerDoc.data() != null) {
        final data = ownerDoc.data()!;
        ownerName = data['name'] ?? ownerName;
        ownerPhone = data['phone'] ?? '';
      }

      final docRef = FirebaseFirestore.instance.collection('bookings').doc();

      final booking = BookingModel(
        id: docRef.id,
        equipmentId: widget.equipment.id,
        equipmentName: widget.equipment.name,
        equipmentImageUrl: widget.equipment.imageUrl,
        ownerId: widget.equipment.ownerId,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        renterId: user.uid,
        renterName: currentUserData?.name ?? 'Farmer User',
        renterPhone: user.phoneNumber ?? (currentUserData?.phone ?? ''),
        bookingDate: _selectedDate,
        totalHours: _selectedHours,
        ratePerHour: widget.equipment.ratePerHour,
        totalAmount: _totalEstimate,
        deliveryNotes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await docRef.set(booking.toMap());
      await NotificationService.sendNotification(
        recipientId: widget.equipment.ownerId,
        title: 'New Rental Request!',
        body:
            '${currentUserData?.name ?? "A farmer"} has requested to rent ${widget.equipment.name}.',
        type: NotificationType.bookingRequest,
        relatedDocId: docRef.id,
      );
      await FCMSenderService.sendPushNotification(
        recipientUserId: widget.equipment.ownerId,
        title: '🚜 New Equipment Booking!',
        body: '${"A farmer"} has requested to rent ${widget.equipment.name}.',
        route: 'bookings',
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF2E7D32),
          size: 54,
        ),
        content: const Text(
          'Booking Request Sent!\nThe machinery owner has been notified to confirm your rental slot.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back to Market',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reserve Machinery',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),

          // Date Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rental Date',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                onPressed: _pickDate,
                icon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hours Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duration (Hours)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: _selectedHours > 1
                        ? () => setState(() => _selectedHours--)
                        : null,
                  ),
                  Text(
                    '$_selectedHours hrs',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setState(() => _selectedHours++),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Estimated Total Calculation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Cost',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '₹${_totalEstimate.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Delivery / Operational Notes
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Notes for driver / farm landmark...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submit Action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isBooking ? null : _confirmBooking,
              child: _isBooking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Send Reservation Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
