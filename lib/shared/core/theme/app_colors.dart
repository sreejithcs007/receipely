import 'package:flutter/material.dart';

class ColorShades {
  final Color c50;
  final Color c100;
  final Color c200;
  final Color c300;
  final Color c400;
  final Color c500;
  final Color c600;
  final Color c700;
  final Color c800;
  final Color c900;

  const ColorShades({
    required this.c50,
    required this.c100,
    required this.c200,
    required this.c300,
    required this.c400,
    required this.c500,
    required this.c600,
    required this.c700,
    required this.c800,
    required this.c900,
  });
}

class AppColors {
  static const primary = ColorShades(
    c50: Color(0xFFFFF6F0),
    c100: Color(0xFFFFECE0),
    c200: Color(0xFFFFD2B8),
    c300: Color(0xFFFFB38F),
    c400: Color(0xFFFF8B5E),
    c500: Color(0xFFFF6430),
    c600: Color(0xFFF04B18),
    c700: Color(0xFFC73610),
    c800: Color(0xFF9E270D),
    c900: Color(0xFF7A1D0B),
  );

  static const secondary = ColorShades(
    c50: Color(0xFFF3FAF6),
    c100: Color(0xFFE4F4EC),
    c200: Color(0xFFC4E7D6),
    c300: Color(0xFF94D2B5),
    c400: Color(0xFF5DB78E),
    c500: Color(0xFF3B9E74),
    c600: Color(0xFF2B805C),
    c700: Color(0xFF22664A),
    c800: Color(0xFF1B503B),
    c900: Color(0xFF143B2C),
  );

  static const black = ColorShades(
    c50: Color(0xFFF9F9F9),
    c100: Color(0xFFF1F1F1),
    c200: Color(0xFFE3E3E3),
    c300: Color(0xFFCDCDCD),
    c400: Color(0xFFB3B3B3),
    c500: Color(0xFF8E8E8E),
    c600: Color(0xFF6E6E6E),
    c700: Color(0xFF4E4E4E),
    c800: Color(0xFF2E2E2E),
    c900: Color(0xFF0F0F0F),
  );

  static const grey = ColorShades(
    c50: Color(0xFFF8F9FA),
    c100: Color(0xFFE9ECEF),
    c200: Color(0xFFDEE2E6),
    c300: Color(0xFFCED4DA),
    c400: Color(0xFFADB5BD),
    c500: Color(0xFF6C757D),
    c600: Color(0xFF495057),
    c700: Color(0xFF343A40),
    c800: Color(0xFF212529),
    c900: Color(0xFF1A1D20),
  );

  static const white = ColorShades(
    c50: Color(0xFFFAF9F6),
    c100: Color(0xFFFDFCFA),
    c200: Color(0xFFF8F6F0),
    c300: Color(0xFFF3F0E6),
    c400: Color(0xFFEDEAD8),
    c500: Color(0xFFE8E4CC),
    c600: Color(0xFFD6D0B4),
    c700: Color(0xFFBAB293),
    c800: Color(0xFF9E9573),
    c900: Color(0xFF827855),
  );

  static const error = ColorShades(
    c50: Color(0xFFFFF5F5),
    c100: Color(0xFFFFE3E3),
    c200: Color(0xFFFFC9C9),
    c300: Color(0xFFFFA8A8),
    c400: Color(0xFFFF8787),
    c500: Color(0xFFFA5252),
    c600: Color(0xFFF03E3E),
    c700: Color(0xFFE03131),
    c800: Color(0xFFC92A2A),
    c900: Color(0xFFB02525),
  );

  static const success = ColorShades(
    c50: Color(0xFFEBFBEE),
    c100: Color(0xFFD3F9D8),
    c200: Color(0xFFB2F2BB),
    c300: Color(0xFF8CE99A),
    c400: Color(0xFF69DB7C),
    c500: Color(0xFF40C057),
    c600: Color(0xFF37B24D),
    c700: Color(0xFF2F9E44),
    c800: Color(0xFF2B8A3E),
    c900: Color(0xFF237032),
  );

  static const warning = ColorShades(
    c50: Color(0xFFFFF9DB),
    c100: Color(0xFFFFF3BF),
    c200: Color(0xFFFFEC99),
    c300: Color(0xFFFFE066),
    c400: Color(0xFFFFD43B),
    c500: Color(0xFFFCC419),
    c600: Color(0xFFFAB005),
    c700: Color(0xFFF59F00),
    c800: Color(0xFFF08C00),
    c900: Color(0xFFE67700),
  );
}
