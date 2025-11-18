import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXAdvancedFilterScreen extends StatelessWidget {
  const BBXAdvancedFilterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Filters'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text('Advanced Filters - Coming Soon'),
      ),
    );
  }
}
