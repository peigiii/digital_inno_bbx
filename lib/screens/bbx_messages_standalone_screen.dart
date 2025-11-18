import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXMessagesStandaloneScreen extends StatelessWidget {
  const BBXMessagesStandaloneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Messages - Coming Soon'),
      ),
    );
  }
}
