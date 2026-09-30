import 'package:flutter/material.dart';

class AppTheme {
  static const String appName = 'أساتذة';

  // ============================================================
  // ألوان اللوجو والهوية البصرية
  // ============================================================
  static const Color primaryDark = Color(0xFF0F2B48); // خلفية الشعار (الكحلي الداكن)
  static const Color primaryColor = Color(0xFF0F2B48); // اللون الرئيسي للتطبيق
  static const Color goldBase = Color(0xFFD4A359); // الذهبي الأساسي
  static const Color goldLight = Color(0xFFF0D283); // الذهبي الفاتح للإضاءة والتمويج
  static const Color accentColor = Color(0xFFD4A359); // التمييز بالذهبي الأساسي

  // ألوان المساعدة والواجهات
  static const Color successColor = Color(0xFF22C55E);
  static const Color errorColor = Color(0xFFDC2626);

  static const Color scaffoldBackground = Color(0xFFF7F8FC);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFE2E8F0); // الفضي/الأبيض الفاتح من اللوجو

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  static ThemeData get theme {
    final baseTheme = ThemeData(useMaterial3: true, brightness: Brightness.light);

    final textTheme = baseTheme.textTheme
        .apply(displayColor: textPrimary, bodyColor: textPrimary)
        .copyWith(
          displayLarge: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 32,
            color: textPrimary,
            height: 1.3,
          ),
          displayMedium: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: textPrimary,
            height: 1.3,
          ),
          displaySmall: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: textPrimary,
            height: 1.3,
          ),
          headlineLarge: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: textPrimary,
            height: 1.3,
          ),
          headlineMedium: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textPrimary,
            height: 1.3,
          ),
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textPrimary,
            height: 1.3,
          ),
          titleLarge: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: textPrimary,
            height: 1.3,
          ),
          titleMedium: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textPrimary,
            height: 1.3,
          ),
          titleSmall: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textPrimary,
            height: 1.3,
          ),
          bodyLarge: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: textPrimary,
            height: 1.5,
          ),
          bodyMedium: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: textPrimary,
            height: 1.5,
          ),
          bodySmall: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: textSecondary,
            height: 1.5,
          ),
          labelLarge: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textPrimary,
            height: 1.3,
          ),
          labelMedium: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: textPrimary,
            height: 1.3,
          ),
          labelSmall: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: textSecondary,
            height: 1.3,
          ),
        );

    return baseTheme.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1E3E62),
        onPrimaryContainer: Colors.white,
        secondary: goldBase,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFEF3C7),
        onSecondaryContainer: Color(0xFF78350F),
        tertiary: goldLight,
        onTertiary: primaryDark,
        error: errorColor,
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF991B1B),
        surface: surfaceColor,
        onSurface: textPrimary,
        surfaceContainerHighest: scaffoldBackground,
        onSurfaceVariant: textSecondary,
        outline: borderColor,
        outlineVariant: borderColor,
        shadow: Color(0x1F000000),
        scrim: Color(0x99000000),
        inverseSurface: textPrimary,
        onInverseSurface: Colors.white,
        inversePrimary: goldBase,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: surfaceColor,
      cardColor: cardColor,
      dividerColor: borderColor,

      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 56,
        titleSpacing: 16,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldBase,
          side: const BorderSide(color: goldBase, width: 1.5),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: errorColor),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: goldBase, width: 2),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        shadowColor: Colors.black12,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    ); // إغلاق baseTheme.copyWith
  } // إغلاق دالة get theme
} // إغلاق class AppTheme
