import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// ثيم ديار — فاتح وداكن، خط Noto Sans Arabic (يدعم عبري/لاتيني أيضًا
/// عبر fallback تلقائي في google_fonts).
abstract final class DyarTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: DyarTokens.brand,
      brightness: b,
      primary: DyarTokens.brand,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? DyarTokens.surfaceDark : DyarTokens.surfaceLight,
    );
    return base.copyWith(
      textTheme: GoogleFonts.notoSansArabicTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? DyarTokens.surfaceDark : Colors.white,
        foregroundColor: isDark ? Colors.white : DyarTokens.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? DyarTokens.cardDark : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DyarTokens.radius),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DyarTokens.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(DyarTokens.ctaHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DyarTokens.radius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? DyarTokens.cardDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DyarTokens.radius),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DyarTokens.radius),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DyarTokens.radius),
          borderSide: const BorderSide(color: DyarTokens.brand, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? DyarTokens.cardDark : Colors.white,
        indicatorColor: DyarTokens.brandLight,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : DyarTokens.inkMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DyarTokens.radius),
        ),
      ),
    );
  }
}
