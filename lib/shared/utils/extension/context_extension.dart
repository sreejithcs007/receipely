import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

extension ContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
  
  ColorShades get primary => colors.primary;
  ColorShades get secondary => colors.secondary;
  ColorShades get black => colors.black;
  ColorShades get grey => colors.grey;
  ColorShades get white => colors.white;
  ColorShades get error => colors.error;
  ColorShades get success => colors.success;
  ColorShades get warning => colors.warning;

  AppTypographyExtension get typography => Theme.of(this).extension<AppTypographyExtension>()!;
}
