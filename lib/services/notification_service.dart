import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ 修复：添加 StreamSubscription 管理，防止内存泄漏
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ 保存订阅引用
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundSubscription;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    // 防止重复初始化
    if (_isInitialized) return;
    
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User GrantedNotificationPermission');
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      final token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // ✅ 保存订阅引用，以便后续可以取消
      _tokenSubscription = _fcm.onTokenRefresh.listen(_saveToken);
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      _isInitialized = true;
    } catch (e) {
      print('NotificationInit Failed: $e');
    }
  }

  /// ✅ 新增：清理资源，取消所有订阅
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _backgroundSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _backgroundSubscription = null;
    _isInitialized = false;
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await docRef.set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('FCM token Saved');
    } catch (e) {
      print('Save FCM token Failure: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        notification.title ?? '',
        notification.body ?? '',
        message.data,
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('User ClickedNotification: ${message.data}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('NotificationByClick: ${response.payload}');
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'bbx_channel',
        'BBX Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: data.toString(),
      );
    } catch (e) {
      print('ShowLocalNotificationFailure: $e');
    }
  }

  /// 发送通知到 Firestore（用于应用内通知）
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('SendNotificationFailure: $e');
    }
  }
  
  /// ✅ 新增：获取用户未读通知数量
  Future<int> getUnreadCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('GetUnreadCountFailure: $e');
      return 0;
    }
  }
  
  /// ✅ 新增：标记通知为已读
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('MarkAsReadFailure: $e');
    }
  }
}
