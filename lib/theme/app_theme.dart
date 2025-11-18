import 'package:flutter/material.dart';

/// BBX 应用统一主题系统
/// 对标 Alibaba、IndiaMART 等领先 B2B 平台
class AppTheme {
  // ============================================================================
  // 颜色系统
  // ============================================================================

  // 主色调 - 绿色系
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFFC8E6C9);

  // 辅助色
  static const Color secondary = Color(0xFFFF9800);  // 橙色 - 强调色
  static const Color accent = Color(0xFF2196F3);     // 蓝色 - 链接

  // 语义色
  static const Color error = Color(0xFFF44336);      // 红色
  static const Color success = Color(0xFF4CAF50);    // 成功绿
  static const Color warning = Color(0xFFFF9800);    // 警告橙
  static const Color info = Color(0xFF2196F3);       // 信息蓝

  // 背景色
  static const Color background = Color(0xFFF5F5F5); // 背景灰
  static const Color surface = Color(0xFFFFFFFF);    // 卡片白

  // 文字色
  static const Color textPrimary = Color(0xFF212121);   // 主文字
  static const Color textSecondary = Color(0xFF757575); // 次文字
  static const Color textHint = Color(0xFF9E9E9E);      // 提示文字
  static const Color textDisabled = Color(0xFFBDBDBD);  // 禁用文字

  // 分割线
  static const Color divider = Color(0xFFBDBDBD);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // ============================================================================
  // 文字样式
  // ============================================================================

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // ============================================================================
  // 圆角规范
  // ============================================================================

  static const double radiusSmall = 4.0;
  static const double radiusStandard = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusRound = 16.0;

  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusStandard = BorderRadius.all(Radius.circular(radiusStandard));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusRound = BorderRadius.all(Radius.circular(radiusRound));

  // ============================================================================
  // 阴影规范
  // ============================================================================

  static const BoxShadow elevation1 = BoxShadow(
    offset: Offset(0, 1),
    blurRadius: 3,
    color: Color(0x14000000), // rgba(0,0,0,0.08)
  );

  static const BoxShadow elevation2 = BoxShadow(
    offset: Offset(0, 2),
    blurRadius: 6,
    color: Color(0x1F000000), // rgba(0,0,0,0.12)
  );

  static const BoxShadow elevation4 = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 8,
    color: Color(0x29000000), // rgba(0,0,0,0.16)
  );

  static const List<BoxShadow> shadowLight = [elevation1];
  static const List<BoxShadow> shadowMedium = [elevation2];
  static const List<BoxShadow> shadowStrong = [elevation4];

  // ============================================================================
  // 间距规范
  // ============================================================================

  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // ============================================================================
  // 组件样式规范
  // ============================================================================

  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardPadding = 16.0;
  static const double cardSpacing = 12.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // ============================================================================
  // 主题配置
  // ============================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // 颜色配置
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        background: background,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),

      // 脚手架背景色
      scaffoldBackgroundColor: background,

      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // 卡片主题
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLarge,
        ),
        margin: const EdgeInsets.all(cardSpacing),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusStandard,
          ),
          elevation: 0,
          textStyle: button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusStandard,
          ),
          side: const BorderSide(color: primary, width: 1.5),
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

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusStandard,
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusStandard,
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusStandard,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusStandard,
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusStandard,
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: body1.copyWith(color: textSecondary),
        hintStyle: body1.copyWith(color: textHint),
        errorStyle: caption.copyWith(color: error),
      ),

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // 图标主题
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: iconSizeMedium,
      ),

      // 文字主题
      textTheme: const TextTheme(
        displayLarge: h1,
        displayMedium: h2,
        displaySmall: h3,
        headlineMedium: h4,
        titleLarge: subtitle1,
        bodyLarge: body1,
        bodyMedium: body2,
        bodySmall: caption,
        labelLarge: button,
      ),
    );
  }

  // 深色主题（可选）
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
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
    );
  }
}
