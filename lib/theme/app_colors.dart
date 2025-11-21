import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================================================
    // ============================================================================
  
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  
  static const Color primary50 = Color(0xFFE8F5E9);
  static const Color primary100 = Color(0xFFC8E6C9);
  static const Color primary200 = Color(0xFFA5D6A7);
  static const Color primary300 = Color(0xFF81C784);
  static const Color primary400 = Color(0xFF66BB6A);
  static const Color primary500 = Color(0xFF4CAF50);    static const Color primary600 = Color(0xFF43A047);
  static const Color primary700 = Color(0xFF388E3C);
  static const Color primary800 = Color(0xFF2E7D32);
  static const Color primary900 = Color(0xFF1B5E20);

  // ============================================================================
    // ============================================================================
  
  static const Color secondary = Color(0xFFF57C00);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);
  
  static const Color secondary50 = Color(0xFFFFF3E0);
  static const Color secondary100 = Color(0xFFFFE0B2);
  static const Color secondary200 = Color(0xFFFFCC80);
  static const Color secondary300 = Color(0xFFFFB74D);
  static const Color secondary400 = Color(0xFFFFA726);
  static const Color secondary500 = Color(0xFFFF9800);
  static const Color secondary600 = Color(0xFFFB8C00);
  static const Color secondary700 = Color(0xFFF57C00);
  static const Color secondary800 = Color(0xFFEF6C00);
  static const Color secondary900 = Color(0xFFE65100);

  // ============================================================================
    // ============================================================================
  
    static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color successDark = Color(0xFF2E7D32);
  
    static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color warningDark = Color(0xFFF57C00);
  
    static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color errorDark = Color(0xFFC62828);
  
    static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFBBDEFB);
  static const Color infoDark = Color(0xFF1976D2);

  // ============================================================================
    // ============================================================================
  
    static const Color text = Color(0xFF212121);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF9E9E9E);
  
    static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
    static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);

  // ============================================================================
    // ============================================================================
  
  static const Color plastic = Color(0xFF2196F3);         static const Color metal = Color(0xFFFF9800);           static const Color paper = Color(0xFF8BC34A);           static const Color glass = Color(0xFF00BCD4);           static const Color electronic = Color(0xFF9C27B0);      static const Color organic = Color(0xFF795548);         static const Color construction = Color(0xFF607D8B);    static const Color textile = Color(0xFFE91E63);         static const Color rubber = Color(0xFF424242);          static const Color others = Color(0xFF9E9E9E);        
  // ============================================================================
    // ============================================================================
  
  static const Color memberFree = Color(0xFF9E9E9E);          static const Color memberBasic = Color(0xFF2196F3);         static const Color memberProfessional = Color(0xFF9C27B0);   static const Color memberEnterprise = Color(0xFFFFD700);   
  // ============================================================================
    // ============================================================================
  
    static Color getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'plastic':
        return plastic;
      case 'metal':
        return metal;
      case 'paper':
        return paper;
      case 'glass':
        return glass;
      case 'electronic':
        return electronic;
      case 'organic':
        return organic;
      case 'construction':
        return construction;
      case 'textile':
        return textile;
      case 'rubber':
        return rubber;
      default:
        return others;
    }
  }

    static Color getCategoryLightColor(String category) {
    return getCategoryColor(category).withOpacity(0.1);
  }

    static Color getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'active':
      case 'available':
      case 'completed':
      case 'accepted':
        return success;
      case 'pending':
      case 'processing':
      case 'in_progress':
        return warning;
      case 'cancelled':
      case 'rejected':
      case 'expired':
        return error;
      case 'draft':
        return textSecondary;
      default:
        return textTertiary;
    }
  }

    static Color getStatusLightColor(String status) {
    return getStatusColor(status).withOpacity(0.1);
  }

    static Color getMembershipColor(String tier) {
    switch (tier.toLowerCase().trim()) {
      case 'free':
        return memberFree;
      case 'basic':
        return memberBasic;
      case 'professional':
        return memberProfessional;
      case 'enterprise':
        return memberEnterprise;
      default:
        return memberFree;
    }
  }

  // ============================================================================
    // ============================================================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary600, primary400],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary700, secondary400],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

    static LinearGradient getCategoryGradient(String category) {
    final color = getCategoryColor(category);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ============================================================================
    // ============================================================================
  
  static Color shadowColor = Colors.black.withOpacity(0.08);
  static Color shadowColorDark = Colors.black.withOpacity(0.16);
  static Color shadowColorLight = Colors.black.withOpacity(0.04);

  // ============================================================================
    // ============================================================================
  
  static Color overlayLight = Colors.black.withOpacity(0.3);
  static Color overlayMedium = Colors.black.withOpacity(0.5);
  static Color overlayDark = Colors.black.withOpacity(0.7);
  
  static Color scrim = Colors.black.withOpacity(0.54);
}

