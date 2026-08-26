import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/features/auth/provider/auth_provider.dart';
import 'package:kissan_connect/features/auth/screens/login_screen.dart';
import 'package:kissan_connect/features/rental/provider/equipment_provider.dart';
import 'package:kissan_connect/firebase_options.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => RentalProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
      ],
      child: MaterialApp(
        title: 'Kissan Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            background: AppColors.background,
          ),
          // textTheme: GoogleFonts.plusJakartaSansTextTheme(
          //   Theme.of(context).textTheme,
          // ),
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
        // Auth Wrapper: automatically check if user is already logged in
        // home: const Scaffold(body: Center(child: Text("Kissan Connect"))),
        home: const LoginScreen(),
      ),
    );
  }
}
