# AI Recipe Generator — Recipely

## Overview

The AI Recipe Generator lets users input available ingredients and receive a custom recipe suggestion. It is powered by a Supabase Edge Function that calls an LLM (OpenAI or Anthropic) server-side, keeping API keys off the client.

**Screen:** `ai_generator_screen.dart`  
**Module path:** `lib/modules/ai_generator/`

---

## Architecture

```
AiGeneratorScreen
    └── AiGeneratorCubit
            └── AiRecipeRepository
                    └── Supabase Edge Function: generate-recipe
                            └── LLM API (OpenAI / Anthropic)
```

The client **never** holds an LLM API key. All AI calls go through the Edge Function.

---

## Supabase Edge Function

**Function name:** `generate-recipe`  
**Method:** `POST`  
**Auth:** Requires Bearer token (user must be signed in)

### Request Payload

```json
{
  "ingredients": ["chicken", "rice", "tomatoes"],
  "servings": 2,
  "preferences": ["quick", "high-protein"]
}
```

### Response Payload

```json
{
  "title": "Cheesy Chicken Tomato Rice",
  "description": "A quick, high-protein one-pan meal.",
  "cookTimeMinutes": 30,
  "calories": 520,
  "servings": 2,
  "difficulty": "easy",
  "ingredients": [
    { "name": "Chicken breast", "amount": "300g" },
    { "name": "Rice", "amount": "1 cup" }
  ],
  "steps": [
    { "order": 1, "instruction": "Season the chicken..." },
    { "order": 2, "instruction": "Cook the rice..." }
  ],
  "tags": ["quick", "high-protein", "one-pan"]
}
```

---

## Repository

```dart
// lib/modules/ai_generator/data/repository/ai_recipe_repository.dart

class AiRecipeRepository {
  final SupabaseClient _client;

  AiRecipeRepository(this._client);

  Future<Result<AiRecipeModel>> generateRecipe({
    required List<String> ingredients,
    int servings = 2,
    List<String> preferences = const [],
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-recipe',
        body: {
          'ingredients': ingredients,
          'servings': servings,
          'preferences': preferences,
        },
      );

      if (response.status != 200) {
        return Result.error('Failed to generate recipe');
      }

      return Result.success(
        AiRecipeModel.fromJson(response.data as Map<String, dynamic>),
      );
    } on FunctionException catch (e) {
      return Result.error(e.details?.toString() ?? 'AI error');
    } catch (e) {
      return Result.error(e.toString());
    }
  }
}
```

---

## State Machine

```dart
// lib/modules/ai_generator/logic/ai_generator_state.dart

abstract class AiGeneratorState {}

class AiGeneratorInitial extends AiGeneratorState {}
class AiGeneratorLoading extends AiGeneratorState {}
class AiGeneratorSuccess extends AiGeneratorState {
  final AiRecipeModel recipe;
  AiGeneratorSuccess(this.recipe);
}
class AiGeneratorError extends AiGeneratorState {
  final String message;
  AiGeneratorError(this.message);
}
```

---

## Ingredient Chip Input

Users type ingredients and press Enter/comma to add them as chips. The chip list is managed in the Cubit state alongside the generated recipe.

```dart
// Cubit method
void addIngredient(String ingredient) {
  final trimmed = ingredient.trim().toLowerCase();
  if (trimmed.isEmpty || _ingredients.contains(trimmed)) return;
  _ingredients.add(trimmed);
  emit(AiGeneratorInitial(ingredients: List.from(_ingredients)));
}

void removeIngredient(String ingredient) {
  _ingredients.remove(ingredient);
  emit(AiGeneratorInitial(ingredients: List.from(_ingredients)));
}
```

---

## Save Generated Recipe

Generated recipes can be saved to the user's profile. On save, the `AiRecipeModel` is written to the `recipes` table with `source: 'ai_generated'` and linked to the user.

```dart
Future<Result<void>> saveGeneratedRecipe(AiRecipeModel recipe, String userId) async {
  try {
    await _client.from('recipes').insert({
      ...recipe.toJson(),
      'user_id': userId,
      'source': 'ai_generated',
      'is_published': false,
    });
    return Result.success(null);
  } on PostgrestException catch (e) {
    return Result.error(e.message);
  }
}
```

---

## UI Notes

- Show a skeleton/shimmer loader while the AI generates.
- Display ingredients as removable chips above the generate button.
- The generated recipe card should match the standard `RecipeCard` widget layout.
- Offer a "Save Recipe" button and a "Try Again" button after generation.
- If the ingredient list is empty, disable the Generate button and show a hint.
