import 'package:flutter/material.dart';

/// 页面转场动画工具类
class PageTransitions {
  /// 淡入淡出转场
  static Route fadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// 从下到上滑动转场
  static Route slideUpTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// 从右到左滑动转场
  static Route slideRightTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// 缩放转场
  static Route scaleTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOut;

        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurvedAnimation(parent: animation, curve: curve),
        );
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// 导航到页面（默认从右到左）
  static Future<T?> navigateTo<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      slideRightTransition(page),
    );
  }

  /// 导航到页面（从下到上）
  static Future<T?> navigateToSlideUp<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      slideUpTransition(page),
    );
  }

  /// 导航到页面（淡入淡出）
  static Future<T?> navigateToFade<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      fadeTransition(page),
    );
  }

  /// 导航到页面（缩放）
  static Future<T?> navigateToScale<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      scaleTransition(page),
    );
  }

  /// 替换当前页面
  static Future<T?> replaceTo<T>(BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, dynamic>(
      context,
      slideRightTransition(page),
    );
  }

  /// 清除所有历史并导航到页面
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      slideRightTransition(page),
      (route) => false,
    );
  }
}
