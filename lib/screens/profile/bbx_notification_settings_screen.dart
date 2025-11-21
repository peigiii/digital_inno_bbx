import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_loading.dart';

/// BBX 通知设置页面
class BBXNotificationSettingsScreen extends StatefulWidget {
  const BBXNotificationSettingsScreen({super.key});

  @override
  State<BBXNotificationSettingsScreen> createState() =>
      _BBXNotificationSettingsScreenState();
}

class _BBXNotificationSettingsScreenState
    extends State<BBXNotificationSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;

  // 通知设置
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;

  // 通知类型
  bool newOffers = true;
  bool offerAccepted = true;
  bool offerRejected = true;
  bool newMessages = true;
  bool transactionUpdates = true;
  bool paymentReminders = true;
  bool marketingNotifications = false;
  bool systemNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final settingsDoc = await FirebaseFirestore.instance
          .collection('user_settings')
          .doc(user!.uid)
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data()!;
        final notifications = data['notifications'] as Map<String, dynamic>?;

        if (notifications != null) {
          setState(() {
            pushNotifications = notifications['push'] ?? true;
            emailNotifications = notifications['email'] ?? true;
            smsNotifications = notifications['sms'] ?? false;

            final types = notifications['types'] as Map<String, dynamic>?;
            if (types != null) {
              newOffers = types['newOffers'] ?? true;
              offerAccepted = types['offerAccepted'] ?? true;
              offerRejected = types['offerRejected'] ?? true;
              newMessages = types['newMessages'] ?? true;
              transactionUpdates = types['transactionUpdates'] ?? true;
              paymentReminders = types['paymentReminders'] ?? true;
              marketingNotifications = types['marketing'] ?? false;
              systemNotifications = types['system'] ?? true;
            }
          });
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('加载通知设置失败: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_settings')
          .doc(user!.uid)
          .set({
        'notifications': {
          'push': pushNotifications,
          'email': emailNotifications,
          'sms': smsNotifications,
          'types': {
            'newOffers': newOffers,
            'offerAccepted': offerAccepted,
            'offerRejected': offerRejected,
            'newMessages': newMessages,
            'transactionUpdates': transactionUpdates,
            'paymentReminders': paymentReminders,
            'marketing': marketingNotifications,
            'system': systemNotifications,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置已保�?),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: BBXFullScreenLoading()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('通知设置'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          // 通知方式
          const Text('通知方式', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacing12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.borderRadiusMedium,
              boxShadow: AppTheme.shadowSmall,
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: '推送通知',
                  subtitle: '接收应用内推送消�?,
                  value: pushNotifications,
                  onChanged: (value) {
                    setState(() => pushNotifications = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: '邮件通知',
                  subtitle: '接收邮件提醒',
                  value: emailNotifications,
                  onChanged: (value) {
                    setState(() => emailNotifications = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.sms_outlined,
                  title: '短信通知',
                  subtitle: '接收短信提醒',
                  value: smsNotifications,
                  onChanged: (value) {
                    setState(() => smsNotifications = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing24),

          // 通知类型
          const Text('通知类型', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacing12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.borderRadiusMedium,
              boxShadow: AppTheme.shadowSmall,
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.local_offer_outlined,
                  title: '新报�?,
                  subtitle: '收到新报价时通知�?,
                  value: newOffers,
                  onChanged: (value) {
                    setState(() => newOffers = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.check_circle_outlined,
                  title: '报价被接�?,
                  subtitle: '报价被接受时通知�?,
                  value: offerAccepted,
                  onChanged: (value) {
                    setState(() => offerAccepted = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.cancel_outlined,
                  title: '报价被拒�?,
                  subtitle: '报价被拒绝时通知�?,
                  value: offerRejected,
                  onChanged: (value) {
                    setState(() => offerRejected = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.chat_bubble_outlined,
                  title: '新消�?,
                  subtitle: '收到新消息时通知�?,
                  value: newMessages,
                  onChanged: (value) {
                    setState(() => newMessages = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.receipt_long_outlined,
                  title: '交易更新',
                  subtitle: '交易状态变更时通知�?,
                  value: transactionUpdates,
                  onChanged: (value) {
                    setState(() => transactionUpdates = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.payment_outlined,
                  title: '支付提醒',
                  subtitle: '支付相关提醒',
                  value: paymentReminders,
                  onChanged: (value) {
                    setState(() => paymentReminders = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing24),

          // 其他通知
          const Text('其他通知', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacing12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.borderRadiusMedium,
              boxShadow: AppTheme.shadowSmall,
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.campaign_outlined,
                  title: '营销通知',
                  subtitle: '接收优惠活动信息',
                  value: marketingNotifications,
                  onChanged: (value) {
                    setState(() => marketingNotifications = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.info_outlined,
                  title: '系统通知',
                  subtitle: '接收系统重要通知（不可关闭）',
                  value: systemNotifications,
                  onChanged: null, // 系统通知不可关闭
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neutral700),
      title: Text(title, style: AppTheme.body1),
      subtitle: Text(subtitle, style: AppTheme.caption),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary500,
      ),
    );
  }
}
