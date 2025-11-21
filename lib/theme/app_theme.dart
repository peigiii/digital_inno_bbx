import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================================
    // ============================================================================

  static const Color primary500 = Color(0xFF2E7D32);
  static const Color primary400 = Color(0xFF43A047);
  static const Color primary300 = Color(0xFF66BB6A);
  static const Color primary200 = Color(0xFFA5D6A7);
  static const Color primary100 = Color(0xFFC8E6C9);
  static const Color primary50 = Color(0xFFE8F5E9);

    static const Color primary = primary500;
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = primary100;
  static const Color primary600 = Color(0xFF388E3C);   static const Color primary700 = Color(0xFF2E7D32);   static const Color primary800 = Color(0xFF1B5E20); 
  // ============================================================================
    // ============================================================================

  static const Color secondary500 = Color(0xFFF57C00);
  static const Color secondary400 = Color(0xFFFB8C00);
  static const Color secondary300 = Color(0xFFFFA726);
  static const Color secondary200 = Color(0xFFFFCC80);
  static const Color secondary100 = Color(0xFFFFE0B2);

    static const Color secondary = secondary500;
  static const Color accent = Color(0xFF2196F3); 
  // ============================================================================
    // ============================================================================

  static const Color neutral900 = Color(0xFF212121);   static const Color neutral800 = Color(0xFF424242);
  static const Color neutral700 = Color(0xFF616161);   static const Color neutral600 = Color(0xFF757575);
  static const Color neutral500 = Color(0xFF9E9E9E);   static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral300 = Color(0xFFE0E0E0);   static const Color neutral200 = Color(0xFFEEEEEE);   static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA);

    static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textLight = neutral500;
  static const Color textHint = neutral500;
  static const Color textDisabled = neutral400;
  static const Color divider = neutral300;
  static const Color dividerLight = neutral300;
  static const Color background = neutral100;
  static const Color backgroundGrey = neutral100;
  static const Color surface = Colors.white;

  // ============================================================================
    // ============================================================================

  static const Color success = Color(0xFF4CAF50);     static const Color warning = Color(0xFFFF9800);     static const Color error = Color(0xFFF44336);       static const Color info = Color(0xFF2196F3);      
  // ============================================================================
    // ============================================================================

  static const Color plastic = Color(0xFF2196F3);        static const Color metal = Color(0xFFFF9800);          static const Color paper = Color(0xFF8BC34A);          static const Color glass = Color(0xFF00BCD4);          static const Color electronic = Color(0xFF9C27B0);     static const Color organic = Color(0xFF795548);        static const Color construction = Color(0xFF607D8B);   static const Color textile = Color(0xFFE91E63);        static const Color others = Color(0xFF9E9E9E);       
    static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
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
      default:
        return others;
    }
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
        return textLight;
    }
  }

  // ============================================================================
    // ============================================================================

  static const double heading1Size = 32.0;    static const double heading2Size = 24.0;    static const double heading3Size = 20.0;    static const double heading4Size = 18.0;
  static const double body1Size = 16.0;       static const double body2Size = 14.0;       static const double captionSize = 12.0;     static const double buttonSize = 16.0;    
  // ============================================================================
    // ============================================================================

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ============================================================================
    // ============================================================================

  static const TextStyle heading1 = TextStyle(
    fontSize: heading1Size,
    fontWeight: bold,
    color: neutral900,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: heading2Size,
    fontWeight: bold,
    color: neutral900,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: heading3Size,
    fontWeight: semibold,
    color: neutral900,
    height: 1.4,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: heading4Size,
    fontWeight: semibold,
    color: neutral900,
    height: 1.4,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: body1Size,
    fontWeight: medium,
    color: neutral900,
    height: 1.5,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: body1Size,
    fontWeight: regular,
    color: neutral900,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: body2Size,
    fontWeight: regular,
    color: neutral700,
    height: 1.5,
  );

  static const TextStyle bodyMedium = body2;

  static const TextStyle caption = TextStyle(
    fontSize: captionSize,
    fontWeight: regular,
    color: neutral600,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: buttonSize,
    fontWeight: semibold,
    height: 1.2,
  );

    static const TextStyle h1 = heading1;
  static const TextStyle h2 = heading2;
  static const TextStyle h3 = heading3;
  static const TextStyle h4 = heading4;

  // ============================================================================
    // ============================================================================

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;     static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

    static const double spacingXS = spacing4;
  static const double spacingSM = spacing8;
  static const double spacingMD = spacing16;
  static const double spacingLG = spacing24;
  static const double spacingXL = spacing32;

  // ============================================================================
    // ============================================================================

  static const double radiusSmall = 4.0;      static const double radiusMedium = 8.0;     static const double radiusLarge = 12.0;     static const double radiusXLarge = 16.0;    static const double radiusFull = 999.0;   
    static const double radiusStandard = radiusMedium;
  static const double radiusRound = radiusXLarge;

    static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusStandard = BorderRadius.all(Radius.circular(radiusStandard));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(radiusXLarge));
  static const BorderRadius borderRadiusRound = BorderRadius.all(Radius.circular(radiusRound));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // ============================================================================
    // ============================================================================

  static const List<BoxShadow> shadowSmall = [BoxShadow(
    offset: Offset(0, 1),
    blurRadius: 3,
    color: Color(0x14000000), // rgba(0,0,0,0.08)
  )];

  static const List<BoxShadow> shadowMedium = [BoxShadow(
    offset: Offset(0, 2),
    blurRadius: 6,
    color: Color(0x1F000000), // rgba(0,0,0,0.12)
  )];

  static const List<BoxShadow> shadowLarge = [BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    color: Color(0x29000000), // rgba(0,0,0,0.16)
  )];

  static const List<BoxShadow> shadowXLarge = [BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 16,
    color: Color(0x33000000), // rgba(0,0,0,0.20)
  )];

    static const List<BoxShadow> elevation1 = shadowSmall;
  static const List<BoxShadow> elevation2 = shadowMedium;
  static const List<BoxShadow> elevation4 = shadowLarge;
  static const List<BoxShadow> elevation8 = shadowXLarge;

    static const List<BoxShadow> shadowLight = elevation1;
  static const List<BoxShadow> shadowNormal = elevation2;
  static const List<BoxShadow> shadowStrong = elevation4;

  // ============================================================================
    // ============================================================================

  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightLarge = 56.0;

  static const double inputHeight = 56.0;
  static const double inputHeightSmall = 48.0;

  static const double cardPadding = 16.0;
  static const double cardSpacing = 12.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 56.0;
  static const double avatarSizeLarge = 80.0;
  static const double avatarSizeXLarge = 100.0;

  static const double bottomNavHeight = 64.0;
  static const double appBarHeight = 80.0;

  // ============================================================================
    // ============================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary500, primary400],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary500, secondary300],
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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

            colorScheme: ColorScheme.light(
        primary: primary500,
        secondary: secondary500,
        error: error,
        background: background,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),

            scaffoldBackgroundColor: background,

            appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: semibold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

            cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        margin: const EdgeInsets.all(cardSpacing),
      ),

            elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary500,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusLarge,
          ),
          elevation: 0,
          textStyle: button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary500,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusLarge,
          ),
          side: const BorderSide(color: primary500, width: 1.5),
          textStyle: button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(double.infinity, buttonHeight),
          textStyle: button,
        ),
      ),

            inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: primary500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: body1.copyWith(color: textSecondary),
        hintStyle: body1.copyWith(color: textHint),
        errorStyle: caption.copyWith(color: error),
      ),

            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary500,
        unselectedItemColor: neutral500,
        selectedLabelStyle: TextStyle(
          fontSize: captionSize,
          fontWeight: semibold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: captionSize,
          fontWeight: regular,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

            dividerTheme: const DividerThemeData(
        color: neutral300,
        thickness: 1,
        space: 1,
      ),

            iconTheme: const IconThemeData(
        color: textPrimary,
        size: iconSizeMedium,
      ),

            textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineMedium: heading4,
        titleLarge: subtitle1,
        bodyLarge: body1,
        bodyMedium: body2,
        bodySmall: caption,
        labelLarge: button,
      ),
    );
  }

  // ============================================================================
    // ============================================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: primary400,
        secondary: secondary400,
        error: error,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
