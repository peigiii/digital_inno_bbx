import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXMyListingsStandaloneScreen extends StatelessWidget {
  const BBXMyListingsStandaloneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('My Listings - Coming Soon'),
      ),
    );
  }
}
