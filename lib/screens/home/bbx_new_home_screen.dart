import 'package:flutter/material.dart';

import 'bbx_optimized_home_screen_safe.dart';

/// 兼容旧路由的包装组件（临时使用测试版�?
/// 任意引用 [BBXNewHomeScreen] 的地方都会自动使用测试版首页
class BBXNewHomeScreen extends StatelessWidget {
  const BBXNewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BBXOptimizedHomeScreenSafe();
  }
}

