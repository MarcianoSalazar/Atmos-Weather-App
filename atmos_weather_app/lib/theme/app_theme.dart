import 'package:flutter/material.dart';

class AtmosTheme {
  // ATMOS Brand Colors - Sky Blue Palette
  static const Color primaryBlue = Color(0xFF1A6EBD);
  static const Color deepBlue = Color(0xFF0D3B6E);
  static const Color skyBlue = Color(0xFF4A9FD4);
  static const Color lightBlue = Color(0xFFB8DFF5);
  static const Color accentBlue = Color(0xFF29ABE2);
  static const Color gradientStart = Color(0xFF1565C0);
  static const Color gradientEnd = Color(0xFF42A5F5);

  // Alert Colors
  static const Color warningRed = Color(0xFFE53935);
  static const Color warningAmber = Color(0xFFF57C00);
  static const Color warningYellow = Color(0xFFFDD835);
  static const Color safeGreen = Color(0xFF43A047);

  // Neutral Colors
  static const Color surfaceWhite = Color(0xFFF8FBFF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textLight = Color(0xFF90A4AE);
  static const Color divider = Color(0xFFE0EAF4);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: accentBlue,
          surface: surfaceWhite,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: primaryBlue.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: cardWhite,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: textSecondary,
          elevation: 12,
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIconColor: Colors.white70,
          suffixIconColor: Colors.white70,
        ),
      );

  static LinearGradient get skyGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, accentBlue, gradientEnd],
        stops: [0.0, 0.5, 1.0],
      );

  static LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryBlue.withOpacity(0.8),
          accentBlue.withOpacity(0.6),
        ],
      );

  static BoxDecoration get backgroundDecoration => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStart, accentBlue, Color(0xFF90CAF9)],
          stops: [0.0, 0.5, 1.0],
        ),
      );
}
