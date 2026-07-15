import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/passenger_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/vehicle_request_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/profile_image_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/change_bank_details_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/admin_trips_provider.dart';
import 'package:aiaprtd_admin_dashboard/features/dashboard_shell/main_dashboard_layout.dart';
import 'package:aiaprtd_admin_dashboard/features/auth/admin_login_page.dart';
import 'package:aiaprtd_admin_dashboard/firebase_options.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: kIsWeb ? false : true,
    sslEnabled: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => PassengerProvider()),
        ChangeNotifierProvider(create: (_) => VehicleRequestProvider()),
        ChangeNotifierProvider(create: (_) => ProfileImageProvider()),
        ChangeNotifierProvider(create: (_) => ChangeBankDetailsProvider()),
        ChangeNotifierProvider(create: (_) => AdminTripsProvider()),
      ],
      child: const AIAPRTDAdminApp(),
    ),
  );
}

class AIAPRTDAdminApp extends StatelessWidget {
  const AIAPRTDAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIAPRTD Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AdminColors.canvas,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.primary,
          primary: AdminColors.primary,
          secondary: AdminColors.driver,
          surface: AdminColors.surface,
          onSurface: AdminColors.ink,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AdminColors.ink,
          displayColor: AdminColors.ink,
          fontFamily: 'Roboto',
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AdminColors.surface,
          foregroundColor: AdminColors.ink,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: AdminColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AdminColors.line),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AdminColors.surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AdminColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AdminColors.primary,
              width: 1.5,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AdminColors.line,
          thickness: 1,
          space: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            minimumSize: const Size(120, 48),
            backgroundColor: AdminColors.ink,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AdminColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AdminLoginPage(),
        '/dashboard': (context) => const MainDashboardLayout(),
      },
    );
  }
}
