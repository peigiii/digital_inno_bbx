import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // 请求权限
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('用户授予通知权限');
      }

      // 初始化本地通知
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

      // 获取并保存 FCM token
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // 监听 token 刷新
      _fcm.onTokenRefresh.listen(_saveToken);

      // 监听前台消息
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 监听后台消息点击
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } catch (e) {
      print('通知初始化失败: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print('保存 FCM token 失败: $e');
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
    // 处理点击通知后的导航
    print('用户点击了通知: ${message.data}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 处理通知点击
    print('通知被点击: ${response.payload}');
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
      print('显示本地通知失败: $e');
    }
  }

  // 发送通知到特定用户
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
      print('发送通知失败: $e');
    }
  }
}
