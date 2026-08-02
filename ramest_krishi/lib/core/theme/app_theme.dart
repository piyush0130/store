import 'package:flutter/material.dart';

class AppTheme {
  // Agriculture Business Theme - Material 3
  
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryAmber = Color(0xFFFF8F00);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        secondary: secondaryAmber,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        secondary: secondaryAmber,
        brightness: Brightness.dark,
      ),
    );
  }
}
