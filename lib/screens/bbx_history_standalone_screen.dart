import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXHistoryStandaloneScreen extends StatelessWidget {
  const BBXHistoryStandaloneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse History'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Browse History - Coming Soon'),
      ),
    );
  }
}
