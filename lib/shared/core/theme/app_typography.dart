import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyleGroup {
  final TextStyle regular;
  final TextStyle medium;
  final TextStyle semibold;
  final TextStyle bold;

  const TextStyleGroup({
    required this.regular,
    required this.medium,
    required this.semibold,
    required this.bold,
  });

  factory TextStyleGroup.create(double size, double height) {
    final heightMultiplier = height / size;
    return TextStyleGroup(
      regular: GoogleFonts.inter(
        fontSize: size,
        height: heightMultiplier,
        fontWeight: FontWeight.w400,
      ),
      medium: GoogleFonts.inter(
        fontSize: size,
        height: heightMultiplier,
        fontWeight: FontWeight.w500,
      ),
      semibold: GoogleFonts.inter(
        fontSize: size,
        height: heightMultiplier,
        fontWeight: FontWeight.w600,
      ),
      bold: GoogleFonts.inter(
        fontSize: size,
        height: heightMultiplier,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  final TextStyleGroup display2xl;
  final TextStyleGroup displayXl;
  final TextStyleGroup displayLg;
  final TextStyleGroup displayMd;
  final TextStyleGroup displaySm;
  final TextStyleGroup displayXs;
  final TextStyleGroup textXl;
  final TextStyleGroup textLg;
  final TextStyleGroup textMd;
  final TextStyleGroup textSm;
  final TextStyleGroup textXs;

  const AppTypographyExtension({
    required this.display2xl,
    required this.displayXl,
    required this.displayLg,
    required this.displayMd,
    required this.displaySm,
    required this.displayXs,
    required this.textXl,
    required this.textLg,
    required this.textMd,
    required this.textSm,
    required this.textXs,
  });

  factory AppTypographyExtension.main() {
    return AppTypographyExtension(
      display2xl: TextStyleGroup.create(72, 90),
      displayXl: TextStyleGroup.create(60, 72),
      displayLg: TextStyleGroup.create(48, 60),
      displayMd: TextStyleGroup.create(36, 44),
      displaySm: TextStyleGroup.create(30, 38),
      displayXs: TextStyleGroup.create(24, 32),
      textXl: TextStyleGroup.create(20, 30),
      textLg: TextStyleGroup.create(18, 28),
      textMd: TextStyleGroup.create(16, 24),
      textSm: TextStyleGroup.create(14, 20),
      textXs: TextStyleGroup.create(12, 18),
    );
  }

  @override
  ThemeExtension<AppTypographyExtension> copyWith({
    TextStyleGroup? display2xl,
    TextStyleGroup? displayXl,
    TextStyleGroup? displayLg,
    TextStyleGroup? displayMd,
    TextStyleGroup? displaySm,
    TextStyleGroup? displayXs,
    TextStyleGroup? textXl,
    TextStyleGroup? textLg,
    TextStyleGroup? textMd,
    TextStyleGroup? textSm,
    TextStyleGroup? textXs,
  }) {
    return AppTypographyExtension(
      display2xl: display2xl ?? this.display2xl,
      displayXl: displayXl ?? this.displayXl,
      displayLg: displayLg ?? this.displayLg,
      displayMd: displayMd ?? this.displayMd,
      displaySm: displaySm ?? this.displaySm,
      displayXs: displayXs ?? this.displayXs,
      textXl: textXl ?? this.textXl,
      textLg: textLg ?? this.textLg,
      textMd: textMd ?? this.textMd,
      textSm: textSm ?? this.textSm,
      textXs: textXs ?? this.textXs,
    );
  }

  @override
  ThemeExtension<AppTypographyExtension> lerp(
    ThemeExtension<AppTypographyExtension>? other,
    double t,
  ) {
    if (other is! AppTypographyExtension) return this;
    return t < 0.5 ? this : other;
  }
}
