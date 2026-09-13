import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // === Design System Color Tokens (UI/UX Pro Max - Spiritual Calm Dark) ===
  static const bgPrimary = Color(0xFF0D0E15);
  static const bgSurface = Color(0xFF161822);
  static const bgCard = Color(0xFF1E202E);
  static const bgElevated = Color(0xFF26293B);
  
  static const primaryEmerald = Color(0xFF10B981);
  static const primaryEmeraldDark = Color(0xFF059669);
  static const primaryEmeraldLight = Color(0xFF34D399);

  static const accentGold = Color(0xFFF59E0B);
  static const accentGoldLight = Color(0xFFFCD34D);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textTertiary = Color(0xFF64748B);
  static const divider = Color(0xFF2E3248);

  // === Gradients ===
  static const emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFF1E202E), Color(0xFF161822)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1A3636), Color(0xFF0D1F1F), Color(0xFF0D0E15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Shadows ===
  static List<BoxShadow> get emeraldGlow => [
        BoxShadow(
          color: primaryEmerald.withValues(alpha: 0.3),
          blurRadius: 18,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryEmerald,
    scaffoldBackgroundColor: bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: primaryEmerald,
      secondary: primaryEmeraldLight,
      surface: bgSurface,
      onSurface: textPrimary,
      onPrimary: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: textSecondary,
      textColor: textPrimary,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryEmerald,
      inactiveTrackColor: bgElevated,
      thumbColor: Colors.white,
      overlayColor: primaryEmerald.withValues(alpha: 0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgSurface,
      selectedItemColor: primaryEmerald,
      unselectedItemColor: textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
      bodySmall: TextStyle(color: textTertiary, fontSize: 11),
    ),
  );
}
