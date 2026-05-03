// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  // Primary Blue Shades
  static const Color primaryDeep = Color(0xFF0A1628);
  static const Color primaryDark = Color(0xFF0D2137);
  static const Color primary = Color(0xFF0F3460);
  static const Color primaryMid = Color(0xFF1A4A8A);
  static const Color primaryLight = Color(0xFF1E6FBA);
  static const Color primaryAccent = Color(0xFF2196F3);
  static const Color primaryBright = Color(0xFF42A5F5);
  static const Color primaryGlow = Color(0xFF64B5F6);
  static const Color primaryPastel = Color(0xFFBBDEFB);

  // Temperature Yellow
  static const Color tempYellow = Color(0xFFFFD600);
  static const Color tempYellowLight = Color(0xFFFFEA00);
  static const Color tempYellowWarm = Color(0xFFFFC107);
  static const Color tempOrange = Color(0xFFFF9800);
  static const Color tempRed = Color(0xFFFF5722);
  static const Color tempCold = Color(0xFF81D4FA);

  // Accent Colors
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentTeal = Color(0xFF00ACC1);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color alertRed = Color(0xFFEF5350);
  static const Color alertOrange = Color(0xFFFF7043);
  static const Color alertYellow = Color(0xFFFFCA28);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color white80 = Color(0xCCFFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white40 = Color(0x66FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);

  // Glass / Frosted
  static const Color glassDark = Color(0x1A1E6FBA);
  static const Color glassMid = Color(0x261E6FBA);
  static const Color glassLight = Color(0x331E6FBA);

  // Surface
  static const Color surface = Color(0xFF0D2137);
  static const Color surfaceLight = Color(0xFF112945);
  static const Color cardBg = Color(0xFF0F3460);
  static const Color cardBgLight = Color(0xFF163A6E);

  // Gradients
  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1628), Color(0xFF0F3460), Color(0xFF1A4A8A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F3460), Color(0xFF163A6E)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A4A8A), Color(0xFF0F3460)],
  );

  static const LinearGradient tempGradient = LinearGradient(
    colors: [Color(0xFFFFD600), Color(0xFFFF9800)],
  );

  static const LinearGradient sunriseGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1565C0), Color(0xFFE65100), Color(0xFFFF8F00)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.tempYellow,
        surface: AppColors.surface,
        onPrimary: AppColors.white,
        onSecondary: AppColors.primaryDeep,
        error: AppColors.alertRed,
      ),
      scaffoldBackgroundColor: AppColors.primaryDeep,
      fontFamily: 'Rajdhani',

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: 2.0,
        ),
        iconTheme: IconThemeData(color: AppColors.white),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.tempYellow,
        unselectedItemColor: AppColors.white60,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 96,
          fontWeight: FontWeight.w700,
          color: AppColors.tempYellow,
          letterSpacing: -2,
          height: 1.0,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 60,
          fontWeight: FontWeight.w700,
          color: AppColors.tempYellow,
          letterSpacing: -1,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 48,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: 1.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 1.0,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white80,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.white80,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.white60,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.white60,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 1.0,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.white10),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.white20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.white20),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
        hintStyle:
            const TextStyle(color: AppColors.white40, fontFamily: 'Rajdhani'),
        prefixIconColor: AppColors.white60,
        suffixIconColor: AppColors.white60,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.white, size: 24),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.white10,
        thickness: 1,
        space: 1,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.tempYellow;
          }
          return AppColors.white40;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent;
          }
          return AppColors.white20;
        }),
      ),

      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryAccent,
        inactiveTrackColor: AppColors.white20,
        thumbColor: AppColors.tempYellow,
        overlayColor: AppColors.glassMid,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryAccent,
        linearTrackColor: AppColors.white10,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassDark,
        labelStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          color: AppColors.white80,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.white10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          color: AppColors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // List Tile
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: AppColors.white,
        iconColor: AppColors.white60,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}
