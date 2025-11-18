import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXFavoritesStandaloneScreen extends StatelessWidget {
  const BBXFavoritesStandaloneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Favorites - Coming Soon'),
      ),
    );
  }
}
