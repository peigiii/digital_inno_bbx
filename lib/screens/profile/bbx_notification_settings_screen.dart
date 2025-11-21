import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_loading.dart';

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

  // Notification Settings
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool smsNotifications = false;

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
      debugPrint('Load settings failed: $e');
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
            content: Text('Settings saved'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
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
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
                    const Text('Notification Methods', style: AppTheme.heading3),
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
                  title: 'Push Notifications',
                  subtitle: 'Receive in-app push messages',
                  value: pushNotifications,
                  onChanged: (value) {
                    setState(() => pushNotifications = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Email Notifications',
                  subtitle: 'Receive email alerts',
                  value: emailNotifications,
                  onChanged: (value) {
                    setState(() => emailNotifications = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.sms_outlined,
                  title: 'SMS Notifications',
                  subtitle: 'Receive SMS alerts',
                  value: smsNotifications,
                  onChanged: (value) {
                    setState(() => smsNotifications = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing24),

                    const Text('Notification Types', style: AppTheme.heading3),
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
                  title: 'New Offers',
                  subtitle: 'Notify on new offers',
                  value: newOffers,
                  onChanged: (value) {
                    setState(() => newOffers = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.check_circle_outlined,
                  title: 'Offer Accepted',
                  subtitle: 'Notify on offer accepted',
                  value: offerAccepted,
                  onChanged: (value) {
                    setState(() => offerAccepted = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.cancel_outlined,
                  title: 'Offer Rejected',
                  subtitle: 'Notify on offer rejected',
                  value: offerRejected,
                  onChanged: (value) {
                    setState(() => offerRejected = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.chat_bubble_outlined,
                  title: 'New Messages',
                  subtitle: 'Notify on new messages',
                  value: newMessages,
                  onChanged: (value) {
                    setState(() => newMessages = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transaction Updates',
                  subtitle: 'Notify on transaction status changes',
                  value: transactionUpdates,
                  onChanged: (value) {
                    setState(() => transactionUpdates = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.payment_outlined,
                  title: 'Payment Reminders',
                  subtitle: 'Payment related notifications',
                  value: paymentReminders,
                  onChanged: (value) {
                    setState(() => paymentReminders = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing24),

                    const Text('Other Notifications', style: AppTheme.heading3),
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
                  title: 'Marketing',
                  subtitle: 'Receive promotional offers',
                  value: marketingNotifications,
                  onChanged: (value) {
                    setState(() => marketingNotifications = value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  icon: Icons.info_outlined,
                  title: 'System',
                  subtitle: 'Important system alerts (cannot be disabled)',
                  value: systemNotifications,
                  onChanged: null,                 ),
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
