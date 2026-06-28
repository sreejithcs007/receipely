# Architecture & State Management — Recipely

This project follows a **feature-based folder structure** with a clear separation of concerns using **Cubit** for state management and a **Repository pattern** for the data layer, backed by **Supabase** instead of a REST API.

---

## Project Structure

`lib/modules/` contains the features of the app. Each module typically includes:

- `data/` — Models and Repositories.
- `logic/` — Cubits for state management.
- `ui/` — Screens and Widgets.

```
lib/
├── main.dart
├── app.dart
├── router/
│   ├── routes.dart
│   └── app_router.dart
├── modules/
│   ├── splash/
│   ├── auth/
│   ├── home/
│   ├── search/
│   ├── recipe_detail/
│   ├── categories/
│   ├── favorites/
│   ├── meal_planner/
│   ├── shopping_list/
│   ├── ai_generator/
│   ├── profile/
│   └── common/
├── shared/
│   ├── di/
│   ├── supabase/
│   ├── services/
│   ├── utils/
│   ├── widgets/
│   ├── core/
│   └── data/
└── l10n/
```

---

## State Management

We use [flutter_bloc](https://pub.dev/packages/flutter_bloc) with **Cubits**.

### Creating a Cubit

1. Define the **State** class (freezed or equatable recommended).
2. Create the **Cubit** class extending `Cubit<State>`.

```dart
class RecipeCubit extends Cubit<RecipeState> {
  final RecipeRepository _repository;

  RecipeCubit(this._repository) : super(RecipeInitial());

  Future<void> loadRecipes() async {
    emit(RecipeLoading());
    final result = await _repository.fetchRecipes();
    if (result.isSuccess) {
      emit(RecipeLoaded(result.data!));
    } else {
      emit(RecipeError(result.message!));
    }
  }
}
```

### Consuming State

Use `BlocBuilder` or `BlocListener` in the UI.

```dart
BlocBuilder<RecipeCubit, RecipeState>(
  builder: (context, state) {
    if (state is RecipeLoading) return const AppLoader();
    if (state is RecipeLoaded) return RecipeGrid(recipes: state.recipes);
    if (state is RecipeError) return ErrorWidget(message: state.message);
    return const SizedBox.shrink();
  },
)
```

---

## Data Layer

The data layer handles Supabase communication and data transformation.

### SupabaseClient

Accessed via `Supabase.instance.client` (initialized in `main.dart`). All direct Supabase calls are isolated inside **Repositories** — never in Cubits or UI.

### Repositories

Repositories abstract the Supabase source from the logic layer. They return `Result<T>` types.

```dart
class RecipeRepository {
  final SupabaseClient _client;

  RecipeRepository(this._client);

  Future<Result<List<RecipeModel>>> fetchRecipes() async {
    try {
      final data = await _client
          .from('recipes')
          .select()
          .order('created_at', ascending: false);
      final recipes = (data as List)
          .map((e) => RecipeModel.fromJson(e))
          .toList();
      return Result.success(recipes);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
}
```

---

## Realtime & Streams

For features like the Shopping List or Meal Planner that need live updates, use Supabase Realtime via streams and expose them from the repository.

```dart
Stream<List<ShoppingItemModel>> watchShoppingList(String userId) {
  return _client
      .from('shopping_list')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map(ShoppingItemModel.fromJson).toList());
}
```

Consume in the Cubit using `emit.forEach` or `StreamSubscription`.

---

## Dependency Injection

All Repositories and Cubits are registered in `lib/shared/di/service_locator.dart` using `get_it`. See `dependency_injection.md` for details.
