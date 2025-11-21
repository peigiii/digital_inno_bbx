import 'package:flutter/material.dart';

class PageTransitions {
    static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
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

    static Route<T> slideUpTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
        final tween = Tween(begin: begin, end: end);

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

    static Route<T> slideRightTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
        final tween = Tween(begin: begin, end: end);

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

    static Route<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOut;

        final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
        final scaleTween = Tween(begin: 0.8, end: 1.0);
        final fadeTween = Tween(begin: 0.0, end: 1.0);

        return ScaleTransition(
          scale: scaleTween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: fadeTween.animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

    static Future<T?> navigateTo<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      slideRightTransition(page),
    );
  }

    static Future<T?> navigateToSlideUp<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      slideUpTransition(page),
    );
  }

    static Future<T?> navigateToFade<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      fadeTransition(page),
    );
  }

    static Future<T?> navigateToScale<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      scaleTransition(page),
    );
  }

    static Future<T?> replaceTo<T>(BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, dynamic>(
      context,
      slideRightTransition(page),
    );
  }

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
