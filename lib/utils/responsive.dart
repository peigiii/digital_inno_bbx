import 'package:flutter/material.dart';

class Responsive {
    static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

    static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

    static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

    static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

    static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

    static int getGridColumns(BuildContext context) {
    return responsive(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

    static double getSpacing(BuildContext context) {
    return responsive(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
  }

    static double getFontScale(BuildContext context) {
    return responsive(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

    static double getDialogMaxWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 600.0,
    );
  }

    static double getContentMaxWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
    );
  }
}
