import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/features/main_navigation_shell.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isInitialSetup;
  const EditProfileScreen({super.key, this.isInitialSetup = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _villageController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;

  File? _pickedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _villageController = TextEditingController(text: user?.village ?? '');
    _districtController = TextEditingController(
      text: user?.district ?? 'Mathura',
    );
    _stateController = TextEditingController(
      text: user?.state ?? 'Uttar Pradesh',
    );
    _uploadedImageUrl = user?.profileImage;
    _selectedLanguage = user?.language ?? 'English';
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
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
        _showSnackBar("Image upload failed");
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnackBar("Upload error: $e");
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<UserProvider>().saveUserProfile(
      name: _nameController.text.trim(),
      village: _villageController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
      profileImageUrl: _uploadedImageUrl,
      language: _selectedLanguage,
    );

    if (success && mounted) {
      _showSnackBar(
        widget.isInitialSetup
            ? "Welcome to Kissan Connect!"
            : "Profile updated successfully!",
      );

      if (widget.isInitialSetup) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.isInitialSetup,
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.isInitialSetup ? 'Complete Your Profile' : 'Edit Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Picker
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_uploadedImageUrl != null &&
                                        _uploadedImageUrl!.isNotEmpty
                                    ? NetworkImage(_uploadedImageUrl!)
                                    : null)
                                as ImageProvider?,
                      child: _isUploadingImage
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : (_uploadedImageUrl == null && _pickedImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 54,
                                    color: AppColors.primary,
                                  )
                                : null),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _isUploadingImage
                            ? null
                            : _pickAndUploadProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Full Name
              const Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter your name'
                    : null,
                decoration: _fieldDecoration(
                  'Enter full name',
                  Icons.person_outline,
                ),
              ),
              const SizedBox(height: 16),

              // Village / Town
              const Text(
                'Village / Area',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _villageController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter village/town' : null,
                decoration: _fieldDecoration(
                  'e.g. Raya, Farah',
                  Icons.home_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // District & State
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'District',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _districtController,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter district'
                              : null,
                          decoration: _fieldDecoration(
                            'Mathura',
                            Icons.location_city_outlined,
                          ),
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
                          'State',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stateController,
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Enter state' : null,
                          decoration: _fieldDecoration(
                            'Uttar Pradesh',
                            Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Language Selector
              const Text(
                'Preferred Language',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: _fieldDecoration('', Icons.language_outlined),
                items: ['English', 'हिंदी (Hindi)', 'पंजाबी (Punjabi)']
                    .map(
                      (lang) =>
                          DropdownMenuItem(value: lang, child: Text(lang)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
              const SizedBox(height: 32),

              // Save Button
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
                  onPressed: (isLoading || _isUploadingImage)
                      ? null
                      : _saveProfile,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.isInitialSetup
                              ? 'Complete Setup'
                              : 'Save Changes',
                          style: const TextStyle(
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

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
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
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
    );
  }
}
