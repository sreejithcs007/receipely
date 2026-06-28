import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:universal_breakpoints/universal_breakpoints.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'shared/core/theme/app_theme.dart';

class RecipelyApp extends StatelessWidget {
  const RecipelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    UniversalBreakpoints().init(context);

    return MaterialApp.router(
      title: 'Recipely',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
