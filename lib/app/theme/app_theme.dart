import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const primaryBlue = Color(0xFF2D2F7F);
  static const gold = Color(0xFFD4A937);

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
    scaffoldBackgroundColor: Colors.white,
    useMaterial3: true,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
