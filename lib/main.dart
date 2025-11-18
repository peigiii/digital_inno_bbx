import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/digital_inno_login_screen.dart';
import 'screens/digital_inno_list_waste_screen.dart';
import 'screens/digital_inno_marketplace_screen.dart';
import 'screens/bbx_home_screen.dart';
import 'screens/bbx_splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/user_initializer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Request permissions
  await _requestPermissions();

  // Initialize notification service
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification service initialization error: $e');
  }

  // Ensure user document exists
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await UserInitializer.ensureUserDocumentExists();
      await UserInitializer.fixUserDocument(currentUser.uid);
      debugPrint('✅ 用户文档初始化完成');
    }
  } catch (e) {
    debugPrint('User initialization error: $e');
  }

  runApp(const BBXApp());
}

Future<void> _requestPermissions() async {
  try {
    // Request permissions individually with error handling
    await Permission.location.request();
    await Permission.camera.request();
    await Permission.notification.request();
    
    // Handle storage permission based on platform
    if (await Permission.storage.isRestricted || 
        await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  } catch (e) {
    debugPrint('Permission request error: $e');
  }
}

class BBXApp extends StatelessWidget {
  const BBXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBX - Borneo Biomass Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF4CAF50),
          surface: Colors.white,
          // Removed deprecated 'background' property
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F8E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
        ),
        useMaterial3: true,
      ),
      home: const BBXSplashScreen(),
      routes: {
        '/login': (context) => const BBXLoginScreen(),
        '/home': (context) => const BBXHomeScreen(),
        '/waste-list': (context) => const BBXListWasteScreen(),
        '/marketplace': (context) => const BBXMarketplaceScreen(),
      },
    );
  }
}