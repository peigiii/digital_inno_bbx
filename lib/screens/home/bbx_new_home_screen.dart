import 'package:flutter/material.dart';

import 'bbx_optimized_home_screen.dart';

/// 兼容旧路由的包装组件
/// 任意引用 [BBXNewHomeScreen] 的地方都会自动使用新版首页
class BBXNewHomeScreen extends StatelessWidget {
  const BBXNewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BBXOptimizedHomeScreen();
  }
}

