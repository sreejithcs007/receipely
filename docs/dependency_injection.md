# Dependency Injection — Recipely

This project uses [get_it](https://pub.dev/packages/get_it) for the Service Locator pattern to handle dependency injection.

## Overview

The setup is located in `lib/shared/di/service_locator.dart`. The global `getIt` instance provides access to all registered dependencies.

---

## Full Registration Example

```dart
// lib/shared/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // ── Supabase Client ──────────────────────────────────────────────────
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ── Services ─────────────────────────────────────────────────────────
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  // ── Repositories ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<RecipeRepository>(
    () => RecipeRepository(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepository(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<MealPlannerRepository>(
    () => MealPlannerRepository(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<ShoppingListRepository>(
    () => ShoppingListRepository(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<AiRecipeRepository>(
    () => AiRecipeRepository(getIt<SupabaseClient>()),
  );
}
```

---

## Usage

### Constructor Injection (Preferred)

Inject dependencies into Cubits via their constructor:

```dart
class RecipeCubit extends Cubit<RecipeState> {
  final RecipeRepository _repository;

  RecipeCubit(this._repository) : super(RecipeInitial());
}
```

### Direct Access (When Necessary)

```dart
final client = getIt<SupabaseClient>();
```

---

## Registering a New Repository

1. Create the repository class in `lib/modules/<feature>/data/repository/`.
2. Add the registration to `setupServiceLocator()`:

```dart
getIt.registerLazySingleton<MyNewRepository>(
  () => MyNewRepository(getIt<SupabaseClient>()),
);
```

3. Use constructor injection in the corresponding Cubit.

---

## Registration Strategies

| Strategy | Use Case |
|---|---|
| `registerLazySingleton` | Most repositories, services (created on first access) |
| `registerSingleton` | Services that must be ready at startup |
| `registerFactory` | Objects that should be freshly created each time |

> **Rule:** Prefer `registerLazySingleton` for all Repositories and Services unless there is a specific reason to create a new instance per use.
