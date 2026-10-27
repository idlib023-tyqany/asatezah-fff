import 'package:flutter/material.dart';

class AppTheme {
  static const String appName = 'أساتذة';

  static const Color primaryDark = Color(0xFF0F2B48);
  static const Color primaryColor = Color(0xFF123A5D);
  static const Color primarySoft = Color(0xFF1F4E7A);
  static const Color secondaryColor = Color(0xFFD4A359);
  static const Color secondarySoft = Color(0xFFF0D283);
  static const Color accentColor = Color(0xFF6EC6FF);

  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFEA580C);
  static const Color errorColor = Color(0xFFDC2626);

  static const Color scaffoldBackgroundLight = Color(0xFFF5F7FB);
  static const Color scaffoldBackgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  static const Color borderColor = borderLight;

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textHintLight = Color(0xFF94A3B8);
  static const Color textSecondary = textSecondaryLight;
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textHintDark = Color(0xFF64748B);

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBackground: scaffoldBackgroundLight,
    surface: surfaceLight,
    card: cardLight,
    border: borderLight,
    textPrimary: textPrimaryLight,
    textSecondary: textSecondaryLight,
    textHint: textHintLight,
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackground: scaffoldBackgroundDark,
    surface: surfaceDark,
    card: cardDark,
    border: borderDark,
    textPrimary: textPrimaryDark,
    textSecondary: textSecondaryDark,
    textHint: textHintDark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surface,
    required Color card,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textHint,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: surface,
      cardColor: card,
      dividerColor: border,
    );

    final textTheme = baseTheme.textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    final refinedTextTheme = textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        height: 1.25,
        color: textPrimary,
      ),
      displayMedium: textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.3,
        color: textPrimary,
      ),
      displaySmall: textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.3,
        color: textPrimary,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        height: 1.3,
        color: textPrimary,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.3,
        color: textPrimary,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 1.3,
        color: textPrimary,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 1.35,
        color: textPrimary,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.35,
        color: textPrimary,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.35,
        color: textPrimary,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.6,
        color: textPrimary,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.6,
        color: textPrimary,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.5,
        color: textSecondary,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.3,
        color: textPrimary,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 1.3,
        color: textPrimary,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        height: 1.3,
        color: textSecondary,
      ),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFFF4D6),
      onSecondaryContainer: const Color(0xFF6B4F00),
      tertiary: secondarySoft,
      onTertiary: primaryDark,
      error: errorColor,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: scaffoldBackground,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      shadow: const Color(0x1A000000),
      scrim: const Color(0x99000000),
      inverseSurface: brightness == Brightness.light ? textPrimary : surface,
      onInverseSurface: brightness == Brightness.light
          ? Colors.white
          : textPrimary,
      inversePrimary: secondaryColor,
    );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      textTheme: refinedTextTheme,
      primaryTextTheme: refinedTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? primaryColor
            : surface,
        foregroundColor: brightness == Brightness.light
            ? Colors.white
            : textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: refinedTextTheme.titleLarge?.copyWith(
          color: brightness == Brightness.light ? Colors.white : textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: brightness == Brightness.light ? Colors.white : textPrimary,
        ),
        toolbarHeight: 56,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: refinedTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: secondaryColor, width: 1.4),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: refinedTextTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: refinedTextTheme.bodyMedium?.copyWith(color: textHint),
        labelStyle: refinedTextTheme.bodyMedium?.copyWith(color: textSecondary),
        errorStyle: refinedTextTheme.bodySmall?.copyWith(color: errorColor),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: refinedTextTheme.titleLarge,
        contentTextStyle: refinedTextTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        contentTextStyle: refinedTextTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
