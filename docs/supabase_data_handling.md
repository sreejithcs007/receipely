# Supabase Data Handling Guide — Recipely

This guide describes how to handle Supabase queries, errors, and data modeling in the app.

## Overview

We use **Supabase Flutter SDK** for backend operations, **JsonSerializable** for models, and the **Repository Pattern** to abstract data access from the logic layer.

---

## 1. Supabase Initialization

Supabase is initialized once in `main.dart` before `runApp`.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  setupServiceLocator();
  runApp(const RecipelyApp());
}
```

The `SupabaseClient` is registered in the service locator:

```dart
getIt.registerLazySingleton<SupabaseClient>(
  () => Supabase.instance.client,
);
```

---

## 2. Creating a Model

Create a model in `lib/modules/<feature>/data/model/`. Annotate with `@JsonSerializable()`.

```dart
import 'package:json_annotation/json_annotation.dart';

part 'recipe_model.g.dart';

@JsonSerializable()
class RecipeModel {
  final String id;
  final String title;
  final String imageUrl;
  final int cookTimeMinutes;
  final int calories;
  final List<String> tags;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  RecipeModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.cookTimeMinutes,
    required this.calories,
    required this.tags,
    required this.createdAt,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeModelFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeModelToJson(this);
}
```

Run `dart run build_runner build -d` to generate the `.g.dart` file.

---

## 3. Creating a Repository

Create a repository in `lib/modules/<feature>/data/repository/`. Inject `SupabaseClient`.

```dart
class RecipeRepository {
  final SupabaseClient _client;

  RecipeRepository(this._client);

  /// Fetch all published recipes, ordered by newest first.
  Future<Result<List<RecipeModel>>> fetchRecipes() async {
    try {
      final data = await _client
          .from('recipes')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final recipes = (data as List)
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.success(recipes);
    } on PostgrestException catch (e) {
      return Result.error(e.message);
    } catch (e) {
      return Result.error(e.toString());
    }
  }

  /// Fetch a single recipe by ID.
  Future<Result<RecipeModel>> fetchRecipeById(String id) async {
    try {
      final data = await _client
          .from('recipes')
          .select()
          .eq('id', id)
          .single();
      return Result.success(RecipeModel.fromJson(data));
    } on PostgrestException catch (e) {
      return Result.error(e.message);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
}
```

---

## 4. Error Handling

Always catch `PostgrestException` (Supabase-specific) separately from generic exceptions.

| Exception Type | Cause | Action |
|---|---|---|
| `PostgrestException` | Database or RLS policy error | Return `Result.error(e.message)` |
| `AuthException` | Auth operation failure | Return `Result.error(e.message)` |
| `StorageException` | File upload/download failure | Return `Result.error(e.message)` |
| Generic `Exception` | Network or unexpected error | Return `Result.error(e.toString())` |

---

## 5. Registering in Service Locator

Add the repository to `lib/shared/di/service_locator.dart`.

```dart
getIt.registerLazySingleton<RecipeRepository>(
  () => RecipeRepository(getIt<SupabaseClient>()),
);
```

---

## 6. Usage in Cubit

Inject the repository into your Cubit and call it.

```dart
final result = await _recipeRepository.fetchRecipes();
if (result.isSuccess) {
  emit(RecipeLoaded(result.data!));
} else {
  emit(RecipeError(result.message!));
}
```

---

## 7. Auth Operations

Auth is handled via `SupabaseClient.auth`. Wrap in `AuthRepository`.

```dart
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<Result<User>> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) return Result.error('Sign in failed');
      return Result.success(response.user!);
    } on AuthException catch (e) {
      return Result.error(e.message);
    } catch (e) {
      return Result.error(e.toString());
    }
  }

  Future<Result<User>> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) return Result.error('Sign up failed');
      return Result.success(response.user!);
    } on AuthException catch (e) {
      return Result.error(e.message);
    } catch (e) {
      return Result.error(e.toString());
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
```

---

## 8. Storage (Recipe Images)

Use `SupabaseClient.storage` for image uploads.

```dart
Future<Result<String>> uploadRecipeImage(File file, String fileName) async {
  try {
    await _client.storage
        .from('recipe-images')
        .upload(fileName, file);
    final url = _client.storage
        .from('recipe-images')
        .getPublicUrl(fileName);
    return Result.success(url);
  } on StorageException catch (e) {
    return Result.error(e.message);
  } catch (e) {
    return Result.error(e.toString());
  }
}
```

---

## 9. Realtime Streams

For live data (e.g., Shopping List, Meal Planner), use Supabase Realtime streams.

```dart
Stream<List<ShoppingItemModel>> watchShoppingList(String userId) {
  return _client
      .from('shopping_list')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((rows) => rows.map(ShoppingItemModel.fromJson).toList());
}
```

> **Note:** Row Level Security (RLS) must be enabled and configured on the Supabase dashboard for user-scoped queries to work correctly.
