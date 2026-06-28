// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Recipely';

  @override
  String get splashTagline => 'Cook. Love. Share.';

  @override
  String get onboarding1Title => 'Discover Thousands of Recipes';

  @override
  String get onboarding2Title => 'AI-Powered Recommendations';

  @override
  String get onboarding3Title => 'Save Favorites & Plan Meals';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get signUpTitle => 'Create Account';

  @override
  String get emailHint => 'Email Address';

  @override
  String get passwordHint => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get createAccount => 'Create Account';

  @override
  String homeGreeting(String name) {
    return 'Good Morning, $name';
  }

  @override
  String get startCooking => 'Start Cooking';

  @override
  String get trendingRecipes => 'Trending Recipes';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get generateRecipe => 'Generate Recipe';

  @override
  String get mealPlannerTitle => 'Meal Planner';

  @override
  String get shoppingListTitle => 'Shopping List';

  @override
  String get searchPlaceholder => 'Search for recipes, ingredients...';

  @override
  String get aiGeneratorTitle => 'AI Recipe Generator';

  @override
  String get profileTitle => 'My Profile';
}
