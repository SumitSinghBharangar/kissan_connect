import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/constants/app_enums.dart';
import 'package:kissan_connect/core/models/equipment_model.dart';
import 'package:kissan_connect/features/rental/provider/equipment_provider.dart';
import 'package:provider/provider.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  EquipmentCategory _selectedCategory = EquipmentCategory.tractor;
  File? _pickedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  final List<EquipmentCategory> _availableCategories = [
    EquipmentCategory.cultivator,
    EquipmentCategory.disc_harrow,
    EquipmentCategory.disc_plough,
    EquipmentCategory.fertilizer_spreader,
    EquipmentCategory.grader,
    EquipmentCategory.harvester,
    EquipmentCategory.land_leveller,
    EquipmentCategory.laser_land_leveller,
    EquipmentCategory.other,
    EquipmentCategory.paddy_transplanter,
    EquipmentCategory.potato_harvester,
    EquipmentCategory.potato_seed_planter,
    EquipmentCategory.reaper,
    EquipmentCategory.rotavator,
    EquipmentCategory.seed_drill,
    EquipmentCategory.sprayer,
    EquipmentCategory.straw_reaper,
    EquipmentCategory.thresher,
    EquipmentCategory.tracter_sprayer,
    EquipmentCategory.tractor,
    EquipmentCategory.trolley,
  ];

  // Cloudinary Pick and Upload function
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
    );

    if (pickedFile == null) return;

    setState(() {
      _pickedImage = File(pickedFile.path);
      _isUploadingImage = true;
    });

    try {
      const cloudName = "dt5tyb0ym";
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = "Jal_Seva";
      request.files.add(
        await http.MultipartFile.fromPath("file", _pickedImage!.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData);
        setState(() {
          _uploadedImageUrl = jsonData['secure_url'];
          _isUploadingImage = false;
        });
      } else {
        setState(() => _isUploadingImage = false);
        _showSnackBar("Image upload failed. Please try again.");
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnackBar("Upload Error: $e");
    }
  }

  // Save Equipment Listing to Firestore
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      _showSnackBar("Please upload a vehicle image");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String uid =
          FirebaseAuth.instance.currentUser?.uid ?? 'guest_farmer';
      final CollectionReference equipmentRef = FirebaseFirestore.instance
          .collection('equipments');
      final DocumentReference doc = equipmentRef.doc();

      final newEquipment = EquipmentModel(
        id: doc.id,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        typeLabel: _selectedCategory.name,
        ratePerHour: num.parse(_rateController.text.trim()),
        location: _locationController.text.trim(),
        rating: 5.0,
        imageUrl: _uploadedImageUrl!,
        isAvailable: true,
        ownerId: uid,
        description: _descController.text.trim(),
        createdAt: DateTime.now(),
      );

      await doc.set(newEquipment.toMap());

      if (mounted) {
        // Refresh local equipment feed
        await context.read<EquipmentProvider>().fetchEquipments();
        _showSnackBar("Vehicle listed successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Error saving equipment: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'List Vehicle for Rent',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Upload Container
              _buildImagePickerBox(),
              const SizedBox(height: 22),

              // 2. Vehicle Name
              const Text(
                'Vehicle / Machine Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter machine name' : null,
                decoration: _inputDecoration('e.g. John Deere 5050D'),
              ),
              const SizedBox(height: 16),

              // 3. Category Selector
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<EquipmentCategory>(
                value: _selectedCategory,
                decoration: _inputDecoration(''),
                items: _availableCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // 4. Rate Per Hour & Location Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rate (₹/hour)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter hourly rate'
                              : null,
                          decoration: _inputDecoration('₹ 1500'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _locationController,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter location'
                              : null,
                          decoration: _inputDecoration('e.g. Mathura, UP'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Description (Optional)
              const Text(
                'Description (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Condition, fuel inclusion, attachments available...',
                ),
              ),
              const SizedBox(height: 28),

              // 6. Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_isUploadingImage || _isSubmitting)
                      ? null
                      : _submitListing,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publish Rental Listing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- IMAGE PICKER CONTAINER ---
  Widget _buildImagePickerBox() {
    return GestureDetector(
      onTap: _isUploadingImage ? null : _pickAndUploadImage,
      child: Container(
        height: 175,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: _isUploadingImage
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 10),
                    Text(
                      'Uploading image to Cloudinary...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : _uploadedImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(_uploadedImageUrl!, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload Vehicle Photo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG up to 10MB',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
    );
  }
}
