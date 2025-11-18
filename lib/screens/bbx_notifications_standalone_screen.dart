import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXNotificationsStandaloneScreen extends StatelessWidget {
  const BBXNotificationsStandaloneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Notifications - Coming Soon'),
      ),
    );
  }
}
