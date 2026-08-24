import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kissan_connect/features/home/screen/home_screen.dart';
import 'package:kissan_connect/homePage.dart';
import '../../core/constants/app_colors.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  // Connected navigation views matching your approved app layout
  final List<Widget> _views = [
    HomeScreen(), // Rent / Buy & Sell Marketplace
    HomePage(), // Rent / Buy & Sell Marketplace
    HomePage(), // Rent / Buy & Sell Marketplace
    const SizedBox(),
    // Dummy slot for center FAB trigger
    const Scaffold(body: Center(child: Text('Expert Advice & Community Chat'))),
    const Scaffold(body: Center(child: Text('Farmer Profile Screen'))),
  ];

  void _openAddListingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Listing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.agriculture, color: AppColors.primary),
              ),
              title: const Text('List Vehicle for Rent'),
              subtitle: const Text('Tractors, Harvesters, Implements'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.storefront, color: AppColors.primary),
              ),
              title: const Text('Sell Crops / Produce'),
              subtitle: const Text('Wheat, Rice, Potatoes, Vegetables'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.help_outline, color: AppColors.primary),
              ),
              title: const Text('Ask Expert Question'),
              subtitle: const Text('Post leaf photo or query to agronomists'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody:
          true, // Allows scroll views to display beneath the frosted blur
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            // iOS Translucent Glass Container Border & Shadow
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ), // Liquid iOS Blur
              child: Container(
                color: Colors.white.withOpacity(
                  0.72,
                ), // Semi-transparent glass tint
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavButton(
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                    _buildNavButton(
                      index: 1,
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront_rounded,
                      label: 'Market',
                    ),
                    // Center Floating Add (+) Button
                    _buildCenterAddButton(context),
                    _buildNavButton(
                      index: 3,
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Chat',
                    ),
                    _buildNavButton(
                      index: 4,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- STANDARD NAV BUTTON CONSTRUCTOR ---
  Widget _buildNavButton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // --- CENTER PROMINENT ADD ACTION (+) ---
  Widget _buildCenterAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddListingSheet(context),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
