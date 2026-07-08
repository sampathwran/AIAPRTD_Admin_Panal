// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// උඹේ files
import 'providers/member_provider.dart';
import 'providers/passenger_provider.dart';
import 'providers/vehicle_request_provider.dart';
import 'providers/profile_image_provider.dart';
import 'providers/change_bank_details_provider.dart';
import 'providers/admin_trips_provider.dart';
import 'screens/main_dashboard_layout.dart';
import 'admin_login_page.dart'; // 💡 අලුතින් හදපු Login Page එක (import එක ෆෝල්ඩර් එක අනුව වෙනස් කරගන්න)
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          surface: const Color(0xFFF8FAFC),
        ),
      ),
      // 💡 මුලින්ම ලෝඩ් වෙන්නේ Admin Login Page එක
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AdminLoginPage(),
        '/dashboard': (context) => const MainDashboardLayout(),
      },
    );
  }
}