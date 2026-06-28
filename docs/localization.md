# Localization — Recipely

This project uses standard Flutter localization with `.arb` files.

## Overview

- **Translation files:** `lib/l10n/`
- **Base file:** `app_en.arb` (English)

---

## How to Add New Strings

1. Open `lib/l10n/app_en.arb`.
2. Add a new key-value pair.

```json
{
  "appTitle": "Recipely",
  "@appTitle": {
    "description": "The name of the app shown in the header"
  },

  "splashTagline": "Cook. Love. Share.",
  "@splashTagline": {},

  "homeGreeting": "Good Morning, {name}",
  "@homeGreeting": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },

  "recipeDetailCookTime": "{minutes} min",
  "@recipeDetailCookTime": {
    "placeholders": {
      "minutes": { "type": "int" }
    }
  },

  "startCooking": "Start Cooking",
  "@startCooking": {},

  "addToFavorites": "Add to Favorites",
  "@addToFavorites": {},

  "generateRecipe": "Generate Recipe",
  "@generateRecipe": {},

  "mealPlannerTitle": "Meal Planner",
  "@mealPlannerTitle": {},

  "shoppingListTitle": "Shopping List",
  "@shoppingListTitle": {}
}
```

3. Save the file. With the Flutter VS Code extension, localization code regenerates automatically.  
   Otherwise run: `flutter gen-l10n`

---

## Usage

Access localized strings via the `context.l10n` extension (set up in `context_extension.dart`):

```dart
// ✅ Preferred — via extension
Text(context.l10n.appTitle);
Text(context.l10n.homeGreeting(user.firstName));

// ❌ Avoid — verbose and noisy
Text(AppLocalizations.of(context)!.appTitle);
```

---

## Key Naming Convention

Use `camelCase` with a feature prefix for clarity:

| Feature | Key Example |
|---|---|
| Global | `appTitle`, `loading`, `errorGeneric` |
| Home | `homeGreeting`, `homeTrendingRecipes` |
| Recipe Detail | `recipeDetailCookTime`, `recipeDetailServings` |
| Search | `searchPlaceholder`, `searchNoResults` |
| Meal Planner | `mealPlannerTitle`, `mealPlannerAddMeal` |
| Shopping List | `shoppingListTitle`, `shoppingListAddItem` |
| AI Generator | `aiGeneratorTitle`, `aiGeneratorPromptHint` |
| Profile | `profileTitle`, `profileCookingLevel` |
| Auth | `loginTitle`, `signUpTitle`, `emailHint`, `passwordHint` |

---

## Notes

- Ensure `BuildContext` is under a `MaterialApp` with localization delegates set up (already done in `main.dart`).
- All user-visible strings **must** use `context.l10n` — no hardcoded English text in widgets.
