import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// BBX 首页 - 安全测试�?
/// 逐步排查白屏问题
class BBXOptimizedHomeScreenSafe extends StatefulWidget {
  const BBXOptimizedHomeScreenSafe({super.key});

  @override
  State<BBXOptimizedHomeScreenSafe> createState() => _BBXOptimizedHomeScreenSafeState();
}

class _BBXOptimizedHomeScreenSafeState extends State<BBXOptimizedHomeScreenSafe> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'BBX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '首页加载测试',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '如果你看到这个页面，说明基本框架正常',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('按钮点击正常')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary500,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('测试按钮'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

