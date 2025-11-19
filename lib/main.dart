import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/digital_inno_login_screen.dart';
import 'screens/digital_inno_list_waste_screen.dart';
import 'screens/home/bbx_new_home_screen.dart';
import 'screens/categories/bbx_categories_screen.dart';
import 'screens/categories/bbx_category_listings_screen.dart';
import 'screens/bbx_listing_detail_screen.dart';
import 'screens/bbx_new_profile_screen.dart';
import 'screens/bbx_splash_screen.dart';
import 'screens/bbx_modern_home_screen.dart';
import 'screens/bbx_market_browse_screen.dart';
import 'screens/bbx_profile_cards_screen.dart';
import 'screens/bbx_subscription_screen.dart';
import 'screens/bbx_subscription_management_screen.dart';
import 'screens/bbx_payment_screen.dart';
import 'screens/bbx_payment_confirmation_screen.dart';
import 'screens/bbx_invoice_screen.dart';
import 'screens/offers/bbx_my_offers_screen.dart';
import 'screens/chat/bbx_conversations_screen.dart';
import 'screens/search/bbx_advanced_search_screen.dart';
import 'screens/transactions/bbx_transactions_screen.dart';
import 'screens/transactions/bbx_transaction_detail_screen.dart';
import 'screens/transactions/bbx_upload_payment_screen.dart';
import 'screens/transactions/bbx_update_logistics_screen.dart';
import 'services/notification_service.dart';
import 'utils/user_initializer.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with timeout
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ Firebase 初始化超时');
        throw Exception('Firebase initialization timeout');
      },
    );
    debugPrint('✅ Firebase 初始化成功');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Start app immediately, don't wait for other initializations
  runApp(const BBXApp());

  // Background initialization - non-blocking
  _backgroundInitialization();
}

/// Background initialization that won't block app startup
Future<void> _backgroundInitialization() async {
  // Request permissions in background
  _requestPermissions().catchError((e) {
    debugPrint('❌ Permission request error: $e');
  });

  // Initialize notification service in background
  NotificationService().initialize().timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      debugPrint('⚠️ 通知服务初始化超时');
    },
  ).catchError((e) {
    debugPrint('❌ Notification service error: $e');
  });

  // Initialize user document in background (only if logged in)
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await UserInitializer.ensureUserDocumentExists().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ 用户文档初始化超时');
        },
      );
      await UserInitializer.fixUserDocument(currentUser.uid).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ 用户文档修复超时');
        },
      );
      debugPrint('✅ 用户文档初始化完成');
    }
  } catch (e) {
    debugPrint('❌ User initialization error: $e');
  }
}

Future<void> _requestPermissions() async {
  try {
    // Request permissions individually with timeout and error handling
    await Permission.location.request().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ Location permission timeout');
        return PermissionStatus.denied;
      },
    );
    
    await Permission.camera.request().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ Camera permission timeout');
        return PermissionStatus.denied;
      },
    );
    
    await Permission.notification.request().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ Notification permission timeout');
        return PermissionStatus.denied;
      },
    );
    
    // Handle storage permission based on platform
    if (await Permission.storage.isRestricted || 
        await Permission.storage.isDenied) {
      await Permission.storage.request().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Storage permission timeout');
          return PermissionStatus.denied;
        },
      );
    }
    
    debugPrint('✅ 权限请求完成');
  } catch (e) {
    debugPrint('❌ Permission request error: $e');
  }
}

class BBXApp extends StatelessWidget {
  const BBXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBX - Borneo Biomass Exchange',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const BBXSplashScreen(),
      routes: {
        '/login': (context) => const BBXLoginScreen(),
        '/home': (context) => const BBXNewHomeScreen(),
        '/categories': (context) => const BBXCategoriesScreen(),
        '/waste-list': (context) => const BBXListWasteScreen(),
        '/profile': (context) => const BBXNewProfileScreen(),
        '/modern-home': (context) => const BBXModernHomeScreen(),
        '/market-browse': (context) => const BBXMarketBrowseScreen(),
        '/profile-cards': (context) => const BBXProfileCardsScreen(),
        '/subscription': (context) => const BBXSubscriptionScreen(),
        '/subscription-management': (context) => const BBXSubscriptionManagementScreen(),
        '/my-offers': (context) => const BBXMyOffersScreen(),
        '/messages': (context) => const BBXConversationsScreen(),
        '/advanced-search': (context) => const BBXAdvancedSearchScreen(),
        '/transactions': (context) => const BBXTransactionsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        if (settings.name == '/payment') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BBXPaymentScreen(
              planName: args['planName'] as String,
              planPrice: args['planPrice'] as int,
              planPeriod: args['planPeriod'] as String,
            ),
          );
        }

        if (settings.name == '/payment-confirmation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BBXPaymentConfirmationScreen(
              planName: args['planName'] as String,
              planPrice: args['planPrice'] as int,
              paymentMethod: args['paymentMethod'] as String,
              success: args['success'] as bool,
            ),
          );
        }

        if (settings.name == '/invoice') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BBXInvoiceScreen(
              paymentId: args['paymentId'] as String,
            ),
          );
        }

        if (settings.name == '/transaction-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BBXTransactionDetailScreen(
              transactionId: args['transactionId'] as String,
            ),
          );
        }

        if (settings.name == '/upload-payment') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BBXUploadPaymentScreen(
              transactionId: args['transactionId'] as String,
            ),
          );
        }

        if (settings.name == '/update-logistics') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BBXUpdateLogisticsScreen(
              transactionId: args['transactionId'] as String,
            ),
          );
        }

        return null;
      },
    );
  }
}