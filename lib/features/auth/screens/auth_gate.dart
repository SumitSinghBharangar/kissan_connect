import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/features/auth/screens/login_screen.dart';
import 'package:kissan_connect/features/main_navigation_shell.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:kissan_connect/features/profile/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb_auth.User?>(
      stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final fb_auth.User? firebaseUser = snapshot.data;

        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<UserProvider>().fetchUserProfile();
              }
            });

            if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
              final data =
                  userDocSnapshot.data!.data() as Map<String, dynamic>?;
              final bool isComplete =
                  data?['isProfileComplete'] as bool? ?? false;

              if (!isComplete) {
                return const EditProfileScreen(isInitialSetup: true);
              }

              return const MainNavigationShell();
            }

            // Brand new registration -> complete profile first
            return const EditProfileScreen(isInitialSetup: true);
          },
        );
      },
    );
  }
}
