# Routing Guide — Recipely

This project uses **Type-Safe Routing** powered by `go_router` and `go_router_builder`. All routes are checked at compile-time.

---

## 1. Basic Concepts

Routes are defined as **classes** in `lib/router/routes.dart`, not as strings.

```dart
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}
```

### Navigation

```dart
// Replace current screen
const HomeRoute().go(context);

// Push onto stack
const RecipeDetailRoute(recipeId: 'abc123').push(context);
```

---

## 2. Route Map

### Auth & Onboarding

```dart
@TypedGoRoute<SplashRoute>(path: '/') 
@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
@TypedGoRoute<LoginRoute>(path: '/login')
@TypedGoRoute<SignUpRoute>(path: '/signup')
```

### Main Shell (Bottom Navigation)

```dart
@TypedShellRoute<MainShellRouteData>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/home'),
    TypedGoRoute<SearchRoute>(path: '/search'),
    TypedGoRoute<MealPlannerRoute>(path: '/meal-planner'),
    TypedGoRoute<FavoritesRoute>(path: '/favorites'),
    TypedGoRoute<ProfileRoute>(path: '/profile'),
  ],
)
```

### Detail & Feature Routes

```dart
@TypedGoRoute<RecipeDetailRoute>(path: '/recipe/:recipeId')
@TypedGoRoute<CategoriesRoute>(path: '/categories')
@TypedGoRoute<CategoryDetailRoute>(path: '/category/:categoryId')
@TypedGoRoute<ShoppingListRoute>(path: '/shopping-list')
@TypedGoRoute<AiGeneratorRoute>(path: '/ai-generator')
@TypedGoRoute<SettingsRoute>(path: '/settings')
@TypedGoRoute<NotificationsRoute>(path: '/notifications')
```

---

## 3. Passing Parameters

### Path Parameters (Required IDs)

```dart
@TypedGoRoute<RecipeDetailRoute>(path: '/recipe/:recipeId')
class RecipeDetailRoute extends GoRouteData {
  final String recipeId;

  const RecipeDetailRoute({required this.recipeId});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RecipeDetailScreen(recipeId: recipeId);
  }
}

// Usage
RecipeDetailRoute(recipeId: recipe.id).push(context);
```

### Query Parameters (Optional Filters)

```dart
@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData {
  final String? q;
  final String? category;

  const SearchRoute({this.q, this.category});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SearchScreen(query: q, category: category);
  }
}

// Usage
const SearchRoute(q: 'pasta', category: 'dinner').go(context);
```

### Extra Objects (Complex Data — Use Sparingly)

```dart
class RecipeDetailRoute extends GoRouteData {
  final RecipeModel $extra;
  const RecipeDetailRoute({required this.$extra});
}

// Usage — data lost on web refresh or deep link
RecipeDetailRoute($extra: recipe).push(context);
```

> ⚠️ Prefer fetching by ID in the detail screen over using `$extra` — it supports deep linking and refresh.

---

## 4. Shell Route (Bottom Navigation)

```dart
// lib/modules/common/ui/main_layout.dart
class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: RecipelyBottomNav(),
    );
  }
}

// In routes.dart
@TypedShellRoute<MainShellRouteData>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/home'),
    TypedGoRoute<SearchRoute>(path: '/search'),
    TypedGoRoute<MealPlannerRoute>(path: '/meal-planner'),
    TypedGoRoute<FavoritesRoute>(path: '/favorites'),
    TypedGoRoute<ProfileRoute>(path: '/profile'),
  ],
)
class MainShellRouteData extends ShellRouteData {
  const MainShellRouteData();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return MainLayout(child: navigator);
  }
}
```

---

## 5. Auth Guard (RouterNotifier)

```dart
// lib/router/router_notifier.dart
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(AuthCubit authCubit) {
    authCubit.stream.listen((_) => notifyListeners());
  }
}

// In AppRouter
redirect: (context, state) {
  final authState = context.read<AuthCubit>().state;
  final isAuth = authState is AuthAuthenticated;
  final isOnAuth = state.matchedLocation == '/login' ||
                   state.matchedLocation == '/signup';

  if (!isAuth && !isOnAuth) return '/login';
  if (isAuth && isOnAuth) return '/home';
  return null;
},
```

---

## 6. Adding New Routes Workflow

1. Open `lib/router/routes.dart`.
2. Define your `GoRouteData` class with `@TypedGoRoute`.
3. Implement the `build` method.
4. Register it in the correct parent (shell route or top-level).
5. Run the generator:

```bash
dart run build_runner build -d
```

6. Use the new route class in navigation calls.
