import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global theme notifier — toggled from profile settings.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class AppTheme {
  // ── Brand colours (shared by both themes) ──
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color accentColor = Color(0xFFE94560);

  // ── Dark palette ──
  static const Color secondaryColor = Color(0xFF2D2D2D);
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color surfaceColor = Color(0xFF16213E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);

  // ── Light palette ──
  static const Color lightBackgroundColor = Color(0xFFF8F9FC);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1B2341);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // ── Context-aware colour helpers ──
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? backgroundColor
          : lightBackgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceColor
          : lightSurfaceColor;

  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : lightTextPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary
          : lightTextSecondary;

  static Color cardBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary.withValues(alpha: 0.08)
          : const Color(0xFFE5E7EB);

  static List<BoxShadow> cardShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? []
          : [
              BoxShadow(
                color: const Color(0xFF1B2341).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: const Color(0xFF1B2341).withValues(alpha: 0.02),
                blurRadius: 1,
                offset: const Offset(0, 0),
              ),
            ];

  // ── Text styles (no color — callers should use .copyWith(color:)) ──
  static TextStyle get appNameStyle => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      );

  static TextStyle get taglineStyle => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        letterSpacing: 1,
      );

  // ── Themes ──
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          surface: surfaceColor,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: lightBackgroundColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: lightSurfaceColor,
          onSurface: lightTextPrimary,
          outline: const Color(0xFFE5E7EB),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light().textTheme,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
      );
}
