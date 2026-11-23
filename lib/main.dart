import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/localization/locale_provider.dart';

import 'package:kissan_connect/core/services/fcm_service.dart';
import 'package:kissan_connect/features/auth/provider/auth_provider.dart';
import 'package:kissan_connect/features/auth/screens/auth_gate.dart';
import 'package:kissan_connect/features/auth/screens/login_screen.dart';
import 'package:kissan_connect/features/auth/screens/otp_verification_screen.dart';
import 'package:kissan_connect/features/chat/screen/chat_screen.dart';
import 'package:kissan_connect/features/profile/provider/user_provider.dart';
import 'package:kissan_connect/features/rental/provider/equipment_provider.dart';
import 'package:kissan_connect/firebase_options.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FCMService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      // Consumer rebuilds MaterialApp whenever locale changes
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Kissan Connect',
            navigatorKey: FCMService.navigatorKey,
            locale: Locale(
              localeProvider.locale,
            ), // <-- Updates native Flutter widgets too
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                surface: AppColors.background,
              ),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.textPrimary),
                titleTextStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            home: const AuthGate(),
            onGenerateRoute: (settings) {
              if (settings.name == '/conversation') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => ConversationScreen(
                    chatRoomId: args['chatRoomId'],
                    peerName: args['peerName'] ?? 'Farmer',
                    // Supports both 'recipientUid' (from FCM) and 'ownerUid'
                    recipientUid:
                        args['recipientUid'] ?? args['ownerUid'] ?? '',
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
