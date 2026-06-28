import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final ColorShades primary;
  final ColorShades secondary;
  final ColorShades black;
  final ColorShades grey;
  final ColorShades white;
  final ColorShades error;
  final ColorShades success;
  final ColorShades warning;

  const AppColorsExtension({
    required this.primary,
    required this.secondary,
    required this.black,
    required this.grey,
    required this.white,
    required this.error,
    required this.success,
    required this.warning,
  });

  factory AppColorsExtension.light() {
    return const AppColorsExtension(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      black: AppColors.black,
      grey: AppColors.grey,
      white: AppColors.white,
      error: AppColors.error,
      success: AppColors.success,
      warning: AppColors.warning,
    );
  }

  factory AppColorsExtension.dark() {
    return const AppColorsExtension(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      black: AppColors.white,
      grey: AppColors.grey,
      white: AppColors.black,
      error: AppColors.error,
      success: AppColors.success,
      warning: AppColors.warning,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    ColorShades? primary,
    ColorShades? secondary,
    ColorShades? black,
    ColorShades? grey,
    ColorShades? white,
    ColorShades? error,
    ColorShades? success,
    ColorShades? warning,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      black: black ?? this.black,
      grey: grey ?? this.grey,
      white: white ?? this.white,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return t < 0.5 ? this : other;
  }
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary.c500,
      scaffoldBackgroundColor: AppColors.white.c50,
      extensions: [
        AppColorsExtension.light(),
        AppTypographyExtension.main(),
      ],
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary.c500,
      scaffoldBackgroundColor: AppColors.black.c900,
      extensions: [
        AppColorsExtension.dark(),
        AppTypographyExtension.main(),
      ],
    );
  }
}
