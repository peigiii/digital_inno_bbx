import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXMyOffersStandaloneScreen extends StatelessWidget {
  const BBXMyOffersStandaloneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quotes'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('My Quotes - Coming Soon'),
      ),
    );
  }
}
