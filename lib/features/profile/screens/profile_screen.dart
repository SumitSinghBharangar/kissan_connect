import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/features/auth/screens/login_screen.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:kissan_connect/features/profile/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: 100,
        ),
        child: Column(
          children: [
            // 1. User Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        user?.profileImage != null &&
                            user!.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user?.profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 36,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true
                              ? user!.name
                              : 'Farmer User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.phone ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                user?.fullAddress ?? 'Mathura, UP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Agricultural & Rental Services Group
            _buildSectionHeader('My Activities'),
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.agriculture_rounded,
                title: 'My Equipment / Vehicles',
                subtitle: 'Manage your active listings',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.assignment_outlined,
                title: 'My Bookings',
                subtitle: 'Track your reserved equipment',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.history_rounded,
                title: 'Rental History',
                subtitle: 'Completed past transactions',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.favorite_border_rounded,
                title: 'Saved & Favorites',
                subtitle: 'Bookmarked machinery and tools',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 20),

            // 3. Settings & App Preferences Group
            _buildSectionHeader('Preferences & Help'),
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Rental alerts and Mandi updates',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.translate_rounded,
                title: 'Language',
                subtitle: user?.language ?? 'English',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.headset_mic_outlined,
                title: 'Help & Support',
                subtitle: 'Kisan helpline & FAQs',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 24),

            // 4. Logout Action Tile
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                onTap: () async {
                  await userProvider.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      CupertinoPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.grey,
      ),
    );
  }
}
