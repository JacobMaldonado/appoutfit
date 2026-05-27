import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Boutique design system.
/// Primary: Charcoal #202F38 | Accent: Dusty Rose #ECBDA4 | Fill: Champagne #F0E0C8
abstract class AppTheme {
  static const Color primary = Color(0xFF202F38);
  static const Color primaryContainer = Color(0xFF36454F);
  static const Color dustyRose = Color(0xFFECBDA4);
  static const Color champagne = Color(0xFFF0E0C8);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color outlineVariant = Color(0xFFC3C7CB);
  static const Color outline = Color(0xFF73777B);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: Color(0xFFA2B2BE),
        secondary: dustyRose,
        onSecondary: Colors.white,
        secondaryContainer: champagne,
        onSecondaryContainer: Color(0xFF795541),
        surface: surface,
        onSurface: onSurface,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
      ),
      scaffoldBackgroundColor: surface,
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      chipTheme: _chipTheme,
      bottomNavigationBarTheme: _bottomNavTheme,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    final playfair = GoogleFonts.playfairDisplayTextTheme(base);
    return playfair.copyWith(
      bodyLarge: GoogleFonts.inter(fontSize: 18, height: 1.55),
      bodyMedium: GoogleFonts.inter(fontSize: 16, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 14, height: 1.43),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 14,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05 * 12,
      ),
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 48,
        height: 1.17,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.33,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
      ),
    );
  }

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: surface,
    foregroundColor: primary,
    elevation: 0,
    scrolledUnderElevation: 1,
    shadowColor: Color(0x0D36454F),
    centerTitle: true,
  );

  static final CardThemeData _cardTheme = CardThemeData(
    color: surfaceCard,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    shadowColor: const Color(0x0D36454F),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x2036454F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2 * 14,
      ),
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: false,
    border: const UnderlineInputBorder(
      borderSide: BorderSide(color: outlineVariant),
    ),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: outlineVariant),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: dustyRose, width: 2),
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: outline,
      letterSpacing: 0.1,
    ),
    hintStyle: GoogleFonts.inter(color: outlineVariant, fontSize: 16),
  );

  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: champagne,
    selectedColor: dustyRose,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: primary,
    ),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  );

  static const BottomNavigationBarThemeData _bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor: surface,
    selectedItemColor: primary,
    unselectedItemColor: outline,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  );
}
