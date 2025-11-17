import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/digital_inno_marketplace_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDummy-Key-For-Development',
        appId: '1:123456789:android:abcdef',
        messagingSenderId: '123456789',
        projectId: 'digital-inno-bbx',
        storageBucket: 'digital-inno-bbx.appspot.com',
      ),
    );
  } catch (e) {
    // Firebase initialization failed - app will show error state in UI
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Innovation Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DigitalInnoMarketplaceScreen(),
    );
  }
}
