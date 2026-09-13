import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFF1DB954);
  static const _primaryDark = Color(0xFF1AA34A);
  static const _background = Color(0xFF121212);
  static const _surface = Color(0xFF1E1E1E);
  static const _surfaceVariant = Color(0xFF282828);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFB3B3B3);
  static const _textTertiary = Color(0xFF6E6E6E);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primary,
    scaffoldBackgroundColor: _background,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      secondary: _primaryDark,
      surface: _surface,
      onSurface: _textPrimary,
      onPrimary: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: _textPrimary),
    ),
    cardTheme: CardTheme(
      color: _surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _textSecondary,
      textColor: _textPrimary,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: _primary,
      inactiveTrackColor: _textTertiary,
      thumbColor: _primary,
      overlayColor: _primary.withOpacity(0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surface,
      selectedItemColor: _primary,
      unselectedItemColor: _textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
      titleLarge: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: _textPrimary, fontSize: 15),
      bodyLarge: TextStyle(color: _textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
      bodySmall: TextStyle(color: _textTertiary, fontSize: 12),
    ),
  );
}
