import 'package:flutter/material.dart';

class BBXTestHomeScreen extends StatelessWidget {
  const BBXTestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('BBXTestHomeScreen build() called');     
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('测试首页'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 100,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 24),
              const Text(
                '?页面加载成功?,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '如果你看到这个页?,
                style: TextStyle(fontSize: 16),
              ),
              const Text(
                '说明路由和基础框架都正?,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  print('按钮被点?);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('交互正常')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  '测试按钮',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR in BBXTestHomeScreen: $e');
      print('StackTrace: $stackTrace');
      
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 100, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                '页面出错',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '错误信息: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
  }
}

