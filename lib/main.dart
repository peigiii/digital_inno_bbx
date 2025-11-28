import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/digital_inno_login_screen.dart';
import 'screens/digital_inno_list_waste_screen.dart';
import 'screens/bbx_new_marketplace_screen.dart';
import 'screens/bbx_listing_detail_screen.dart';
// import 'screens/bbx_new_profile_screen.dart'; // 已删除，使用profile/bbx_optimized_profile_screen.dart
import 'screens/bbx_splash_screen.dart';
import 'screens/bbx_main_screen.dart';
import 'screens/bbx_modern_home_screen.dart';
import 'screens/bbx_market_browse_screen.dart';
import 'screens/bbx_profile_cards_screen.dart';
import 'screens/bbx_subscription_screen.dart';
import 'screens/bbx_subscription_management_screen.dart';
import 'screens/bbx_rewards_screen.dart';
import 'screens/bbx_payment_screen.dart';
import 'screens/bbx_payment_confirmation_screen.dart';
import 'screens/bbx_invoice_screen.dart';
import 'screens/transactions/bbx_optimized_transaction_detail_screen.dart';
import 'screens/offers/bbx_my_offers_screen.dart';
import 'screens/chat/bbx_conversations_screen.dart';
import 'screens/search/bbx_advanced_search_screen.dart';
import 'screens/search/bbx_new_search_screen.dart'; // ✅ 添加搜索页面
import 'screens/categories/bbx_categories_screen.dart'; // ✅ 添加分类页面
import 'screens/bbx_my_listings_standalone_screen.dart'; // ✅ 添加我的列表页面
import 'screens/transactions/bbx_transactions_screen.dart';
// import 'screens/transactions/bbx_transaction_detail_screen.dart'; // 未使用，路由使用BBXOptimizedTransactionDetailScreen
import 'screens/transactions/bbx_upload_payment_screen.dart';
import 'screens/transactions/bbx_update_logistics_screen.dart';
import 'screens/profile/bbx_optimized_profile_screen.dart';
import 'screens/profile/bbx_wallet_screen.dart';
import 'screens/profile/bbx_coupons_screen.dart';
import 'screens/profile/bbx_statistics_screen.dart';
import 'screens/profile/bbx_account_settings_screen.dart';
import 'screens/profile/bbx_notification_settings_screen.dart';
import 'screens/bbx_favorites_standalone_screen.dart';
import 'services/notification_service.dart';
import 'utils/user_initializer.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

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
      debugPrint('[Done] Init complete');
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const BBXSplashScreen(),
      routes: {
        '/login': (context) => const BBXLoginScreen(),
        // '/home' moved to onGenerateRoute to support arguments
        '/waste-list': (context) => const BBXListWasteScreen(),
        '/marketplace': (context) => const BBXNewMarketplaceScreen(),
        '/profile': (context) => const BBXOptimizedProfileScreen(),
        '/modern-home': (context) => const BBXModernHomeScreen(),
        '/market-browse': (context) => const BBXMarketBrowseScreen(),
        '/profile-cards': (context) => const BBXProfileCardsScreen(),
        '/subscription': (context) => const BBXSubscriptionScreen(),
        '/subscription-management': (context) => const BBXSubscriptionManagementScreen(),
        '/my-offers': (context) => const BBXMyOffersScreen(),
        '/messages': (context) => const BBXConversationsScreen(),
        '/advanced-search': (context) => const BBXAdvancedSearchScreen(),
        '/transactions': (context) => const BBXTransactionsScreen(),
        '/wallet': (context) => const BBXWalletScreen(),
        '/rewards': (context) => const BBXRewardsScreen(),
        '/coupons': (context) => const BBXCouponsScreen(),
        '/statistics': (context) => const BBXStatisticsScreen(),
        '/account-settings': (context) => const BBXAccountSettingsScreen(),
        '/notification-settings': (context) => const BBXNotificationSettingsScreen(),
        '/favorites': (context) => const BBXFavoritesStandaloneScreen(),
        // ✅ 新增缺失的路由
        '/search': (context) => const BBXNewSearchScreen(),
        '/categories': (context) => const BBXCategoriesScreen(),
        '/edit-profile': (context) => const BBXAccountSettingsScreen(), // 编辑资料复用账户设置页
        '/my-listings': (context) => const BBXMyListingsStandaloneScreen(),
        '/create-listing': (context) => const BBXListWasteScreen(), // 创建列表复用发布废料页
      },
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>?;
          final initialIndex = args?['index'] as int? ?? 0;
          return MaterialPageRoute(
            builder: (context) => BBXMainScreen(initialIndex: initialIndex),
          );
        }

        if (settings.name == '/listing-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BBXListingDetailScreen(
              listingId: args['listingId'] as String,
            ),
          );
        }

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
            builder: (context) => BBXOptimizedTransactionDetailScreen(
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
