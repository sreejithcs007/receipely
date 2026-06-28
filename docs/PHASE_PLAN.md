# Recipely — Phase-by-Phase Implementation Plan

> **App:** Recipely — Cook. Love. Share.  
> **Backend:** Supabase (Auth, Database, Storage, Realtime, Edge Functions)  
> **Architecture:** Feature-First, Cubit + Repository, Type-Safe Routing  
> **Package:** com.recipely.app  

---

## Screens Reference (from design)

| # | Screen | Module |
|---|---|---|
| 1 | Splash | `splash` |
| 2–4 | Onboarding (3 slides) | `onboarding` |
| 5 | Login / Sign Up | `auth` |
| 6 | Home Dashboard | `home` |
| 7 | Recipe Detail | `recipe_detail` |
| 8 | Search | `search` |
| 9 | Categories | `categories` |
| 10 | Favorites | `favorites` |
| 11 | Meal Planner | `meal_planner` |
| 12 | Shopping List | `shopping_list` |
| 13 | AI Generator | `ai_generator` |
| 14 | Profile | `profile` |

---

## Architecture Laws (Always Enforced)

| ❌ Never | ✅ Always |
|---|---|
| `Colors.orange` or hardcoded hex | `context.primary.c500` |
| `TextStyle(fontSize: 16)` | `context.typography.textMd.regular` |
| Hardcoded strings in widgets | `context.l10n.someKey` |
| `'assets/images/logo.png'` | `Assets.images.logo.path` |
| Direct Supabase calls in Cubits or UI | Only inside Repositories |
| Module-level DI or direct instantiation | `getIt<MyRepository>()` |
| Feature-specific widgets in `shared/widgets/` | Only atomic/reusable components |

---

## Phase 1: pubspec.yaml — Dependencies

**Goal:** Configure all packages before writing any Dart code.

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Backend
  supabase_flutter: ^2.5.6

  # Navigation
  go_router: ^14.2.0

  # DI
  get_it: ^7.7.0

  # Code Generation
  json_annotation: ^4.9.0

  # Theming
  google_fonts: ^6.2.1
  universal_breakpoints: ^2.1.0

  # Storage
  flutter_secure_storage: ^9.2.2

  # Localization
  intl: ^0.19.0

  # Image handling
  cached_network_image: ^3.3.1

  # UI Helpers
  shimmer: ^3.0.0
  flutter_svg: ^2.0.10+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  json_serializable: ^6.8.0
  go_router_builder: ^14.0.0
  flutter_gen_runner: ^5.7.0
  envied_generator: ^0.5.4
  flutter_lints: ^4.0.0

flutter:
  generate: true   # enables l10n generation
  assets:
    - assets/images/
    - assets/icons/
    - assets/lottie/
```

**Command after:** `flutter pub get`

---

## Phase 2: Folder Structure

**Goal:** Create the complete directory tree. No extras, no omissions.

```
lib/
├── main.dart
├── app.dart
├── env.dart                          # @Envied config
├── gen/                              # FlutterGen output (auto)
├── l10n/
│   └── app_en.arb
├── router/
│   ├── routes.dart
│   ├── routes.gr.dart               # Generated
│   └── app_router.dart
├── modules/
│   ├── splash/
│   │   └── ui/screens/
│   ├── onboarding/
│   │   └── ui/screens/
│   ├── auth/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/screens/
│   ├── home/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/
│   │       ├── screens/
│   │       └── widgets/
│   ├── recipe_detail/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/
│   │       ├── screens/
│   │       └── widgets/
│   ├── search/
│   │   ├── logic/
│   │   └── ui/screens/
│   ├── categories/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/screens/
│   ├── favorites/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/screens/
│   ├── meal_planner/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/
│   │       ├── screens/
│   │       └── widgets/
│   ├── shopping_list/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/screens/
│   ├── ai_generator/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/screens/
│   ├── profile/
│   │   ├── data/model/
│   │   ├── data/repository/
│   │   ├── logic/
│   │   └── ui/screens/
│   └── common/
│       ├── logic/
│       └── ui/
│           ├── layouts/
│           └── widgets/
├── shared/
│   ├── core/
│   │   ├── constants/
│   │   └── theme/
│   ├── data/
│   │   └── model/
│   ├── di/
│   │   └── service_locator.dart
│   ├── services/
│   ├── utils/
│   │   ├── debouncer/
│   │   ├── dev/
│   │   └── extension/
│   └── widgets/
│       ├── app_bar/
│       ├── avatar/
│       ├── bottom_sheets/
│       ├── buttons/
│       ├── cards/
│       ├── chips/
│       ├── layout/
│       ├── loader/
│       └── search_bar/
└── assets/
    ├── images/
    ├── icons/
    └── lottie/
```

---

## Phase 3: Core Infrastructure

**Goal:** Implement all foundational Dart files — no feature code yet.

### 3.1 Result Type
`lib/shared/data/model/result.dart`

```dart
class Result<T> {
  final T? data;
  final String? message;
  final bool isSuccess;

  Result._({this.data, this.message, required this.isSuccess});

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.error(String message) =>
      Result._(message: message, isSuccess: false);
}
```

### 3.2 Supabase Client (via Env)
`lib/env.dart` — `@Envied` reading `.env`
`lib/main.dart` — `Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey)`

### 3.3 Service Locator
`lib/shared/di/service_locator.dart`

Register:
- `SupabaseClient` → `Supabase.instance.client`
- `StorageService`
- `AuthRepository`, `RecipeRepository`, `FavoritesRepository`
- `MealPlannerRepository`, `ShoppingListRepository`
- `UserRepository`, `AiRecipeRepository`, `CategoryRepository`

### 3.4 Theming
- `app_colors.dart` — Warm orange primary, green secondary, cream white
- `app_typography.dart` — Inter font, full size scale
- `app_theme.dart` — `ThemeData` with both extensions + light/dark

### 3.5 Constants
- `app_constants.dart` — Pagination sizes, cache TTLs
- `dimensions.dart` — Spacing grid (4, 8, 12, 16, 24, 32, 48), border radii

### 3.6 Context Extensions
`context_extension.dart` — `.primary`, `.typography`, `.l10n`  
`string_extension.dart`  
`number.dart` — `.sW`, `.sH`, `.sF`  
`date_extension.dart` — formatted meal planner dates

### 3.7 Services
- `storage_service.dart` — Secure storage wrapper
- `token_storage.dart` — Supabase session persistence
- `user_cache_service.dart` — Cached profile data

### 3.8 Dev Utilities
- `dev_logger.dart` — Conditional debug logging
- `debouncer.dart` — Search input debounce (300ms)

---

## Phase 4: Shared Widgets

**Goal:** Build all atomic cross-module UI components.

| Widget | Path | Notes |
|---|---|---|
| `PrimaryButton` | `buttons/primary_button.dart` | Orange CTA, loading state |
| `SecondaryButton` | `buttons/secondary_button.dart` | Outlined variant |
| `RecipeCard` | `cards/recipe_card.dart` | Title, image, time, kcal — used everywhere |
| `CategoryCard` | `cards/category_card.dart` | Icon + label |
| `AppAppBar` | `app_bar/app_appbar.dart` | Recipely branded appbar |
| `AppLoader` | `loader/app_loader.dart` | Centered circular indicator |
| `ShimmerCard` | `loader/shimmer_card.dart` | Skeleton for recipe cards |
| `AppBottomSheet` | `bottom_sheets/app_bottom_sheet.dart` | Styled drag handle + content |
| `ProfileAvatar` | `avatar/profile_avatar.dart` | Circle avatar with fallback |
| `AppSearchBar` | `search_bar/search_bar.dart` | Debounced search input |
| `IngredientChip` | `chips/ingredient_chip.dart` | Removable tag chip |
| `TagChip` | `chips/tag_chip.dart` | Read-only tag display |
| `EmptyStateWidget` | `layout/empty_state_widget.dart` | Icon + message + CTA |
| `NoInternetScreen` | `layout/no_internet_screen.dart` | Connectivity fallback |
| `NutritionBadge` | `cards/nutrition_badge.dart` | Protein/Carbs/Fat/Calories |

---

## Phase 5: Common Module Cubits

`lib/modules/common/logic/`

- `theme_cubit.dart` — Light/dark mode toggle, persisted in secure storage
- `connectivity_cubit.dart` — Network state watcher
- `auth_status_cubit.dart` — Global auth state driving router redirect
- `user_profile_cubit.dart` — Logged-in user data accessible app-wide

---

## Phase 6: Auth Module

**Goal:** Full Supabase auth wiring. Screens are functional, not just stubs.

### Data
- `user_model.dart` — `@JsonSerializable`, maps Supabase `profiles` table
- `auth_repository.dart` — `signInWithEmail`, `signUpWithEmail`, `signOut`, `currentUser`, `authStateChanges`

### Logic
`auth_cubit.dart` + `auth_state.dart`

States: `AuthInitial` → `AuthLoading` → `AuthAuthenticated(user)` | `AuthUnauthenticated` | `AuthError(message)`

### Screens
- `login_screen.dart` — Email + password fields, "Sign In" button, "Don't have an account? Sign Up" link
- `sign_up_screen.dart` — Name, email, password fields, "Create Account" button
- Social login buttons (Google via Supabase OAuth) — optional, add in Phase 10

---

## Phase 7: Routing + main.dart

**Goal:** Type-safe routing, auth guards, shell route with bottom nav.

### Routes

```
/ (SplashRoute)
/onboarding (OnboardingRoute)
/login (LoginRoute)
/signup (SignUpRoute)
Shell:
  /home (HomeRoute)
  /search (SearchRoute)
  /meal-planner (MealPlannerRoute)
  /favorites (FavoritesRoute)
  /profile (ProfileRoute)
/recipe/:recipeId (RecipeDetailRoute)
/category/:categoryId (CategoryDetailRoute)
/shopping-list (ShoppingListRoute)
/ai-generator (AiGeneratorRoute)
/notifications (NotificationsRoute)
/settings (SettingsRoute)
```

### Auth Guard

```dart
redirect: (context, state) {
  final auth = context.read<AuthStatusCubit>().state;
  final isAuth = auth is AuthAuthenticated;
  final path = state.matchedLocation;

  final publicPaths = ['/login', '/signup', '/onboarding', '/'];
  if (!isAuth && !publicPaths.contains(path)) return '/login';
  if (isAuth && (path == '/login' || path == '/signup')) return '/home';
  return null;
},
```

### main.dart

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

Wired with: `MultiBlocProvider`, `MaterialApp.router`, localization delegates, theme.

---

## Phase 8: Env + Localization + Assets

### `.env`
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### `lib/l10n/app_en.arb` — Initial Keys
`appTitle`, `splashTagline`, `onboarding1Title`, `onboarding2Title`, `onboarding3Title`, `loginTitle`, `signUpTitle`, `emailHint`, `passwordHint`, `signIn`, `createAccount`, `homeGreeting`, `startCooking`, `trendingRecipes`, `addToFavorites`, `generateRecipe`, `mealPlannerTitle`, `shoppingListTitle`, `searchPlaceholder`, `aiGeneratorTitle`, `profileTitle`

### Assets
```
assets/images/   ← logo, splash hero, onboarding illustrations
assets/icons/    ← bottom nav icons (SVG), category icons
assets/lottie/   ← loading animation, empty state animation
```

---

## Phase 9: Code Generation

Run in order:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run
```

Confirm the app builds and the shell route renders before moving forward.

---

## Phase 10: Splash + Onboarding Screens

### Splash
- Full-screen warm orange-to-cream gradient
- Centered logo + "Cook. Love. Share." tagline
- 2.5s delay → check auth → route to `/home` (auth) or `/onboarding` (new user)

### Onboarding (3 slides)
- Slide 1: "Discover Thousands of Recipes" — illustration of food collage
- Slide 2: "AI-Powered Recommendations" — illustration of phone + sparkle
- Slide 3: "Save Favorites & Plan Meals" — illustration of calendar + heart
- Progress dots, Next/Get Started button
- Skip button (top right) → jumps to Login

---

## Phase 11: Home Dashboard

**Screens:** `home_screen.dart`

### Data
- `recipe_model.dart` — Full recipe model
- `home_repository.dart` — `fetchTrendingRecipes()`, `fetchRecommendedRecipes()`, `fetchCategories()`

### Layout (from design)
```
AppBar: "Good Morning, {name}" + Avatar
SearchBar → navigates to /search
Category row (horizontal scroll): Breakfast, Lunch, Dinner, Dessert, More
Featured Recipe card (large)
"Trending Recipes" section → horizontal scroll of RecipeCards
  - Spicy Ramen | Grilled Chicken | Avocado Toast
Bottom Navigation
```

### Widgets
- `FeaturedRecipeCard` — large hero card with gradient overlay
- `HomeCategoryRow` — horizontal chip/tab row
- `SectionHeader` — "Trending Recipes →" with "See All" link

---

## Phase 12: Recipe Detail

**Route:** `/recipe/:recipeId`

### Data
- `recipe_detail_model.dart` — Extended model with ingredients, steps, nutrition, chef info
- `recipe_detail_repository.dart` — `fetchRecipeById`, `fetchSimilarRecipes`, `toggleFavorite`

### Layout (from design)
```
Full-bleed hero image + back arrow + bookmark icon
Recipe title, rating (4.8, 2.3k), cook time, calories
Nutrition row: Protein | Carbs | Fat | Servings
Tab bar: Ingredients | Steps | Nutrition | Chef
Ingredients tab: checkbox list with amounts
Steps tab: numbered instructions with timers
Start Cooking button (sticky bottom)
```

### Widgets
- `NutritionRow` — 4 badges in a row
- `IngredientTile` — checkbox + amount + name
- `StepTile` — numbered step with optional timer
- `RatingBar` — star display

---

## Phase 13: Search Screen

**Route:** `/search`

### Data
- Search is a Supabase full-text search query on `recipes` using `ilike` or `fts`

### Features
- Search history (stored locally in secure storage)
- Trending searches (static from config or Supabase `trending_searches` table)
- Filter chips: Cuisine, Diet, Time, Calories
- Popular Recipes section (shown when search bar is empty)
- Results grid (shown on search)

### Cubit
- Debounced search (300ms via `Debouncer`)
- State: `SearchInitial` | `SearchLoading` | `SearchResults(recipes, query)` | `SearchEmpty(query)` | `SearchError`

---

## Phase 14: Categories Screen

**Route:** `/categories`  
**Route:** `/category/:categoryId`

### Data
- `category_model.dart`
- `category_repository.dart` — `fetchCategories()`, `fetchRecipesByCategory(id)`

### Layout (from design)
```
Grid of category cards (2 columns):
  Breakfast | Lunch | Dinner | Desserts | Drinks | Healthy
  Vegan | Indian | Italian | Chinese | Mexican | Seafood
  Snacks | Soup | Baking
```

Each category shows icon + label + recipe count.

---

## Phase 15: Favorites Screen

**Route:** `/favorites`

### Data
- `favorites_repository.dart` — `fetchFavorites(userId)`, `toggleFavorite(userId, recipeId)`
- Favorites join query: `favorite_recipes` → `recipes`

### Layout (from design)
```
Tab bar: All Recipes | Collections | Chefs
Collections sub-tab: user-created recipe collections
Saved Recipes: vertical list of RecipeCards with time + kcal
```

### Widgets
- `FavoritesTabBar` — 3 tabs
- `CollectionCard` — grid item with recipe count badge

---

## Phase 16: Meal Planner

**Route:** `/meal-planner`

See `meal_planner.md` for full implementation details.

### Layout (from design)
```
Week header: "May 20 – May 26" with ← → navigation
Day columns: Mon Tue Wed Thu Fri Sat Sun
  Each column:
    Breakfast slot
    Lunch slot
    Dinner slot
Nutrition Summary: Calories 1850 / 2300 kcal
```

---

## Phase 17: Shopping List

**Route:** `/shopping-list`

### Data
- `shopping_item_model.dart`
- `shopping_list_repository.dart` — `watchShoppingList`, `addItem`, `toggleItem`, `deleteItem`, `clearChecked`

### Layout (from design)
```
Category sections: Vegetables | Meat | Dairy | Spices
Each item: checkbox + name + optional quantity
FAB: + Add Item
Header icons: filter/sort, share list
```

### Features
- Realtime sync (Supabase stream) — changes from one device appear instantly
- Auto-populate from Meal Planner recipes ("Add missing ingredients")
- Swipe-to-delete on items

---

## Phase 18: AI Recipe Generator

**Route:** `/ai-generator`

See `ai_recipe_generator.md` for full implementation details.

### Layout (from design)
```
Header: "What ingredients do you have?"
Ingredient chip input (text field + chip list)
Quick-add suggestion chips: Chicken | Rice | Tomatoes | Cheese
"Generate Recipe" button
AI Suggests section (result card):
  Recipe name + difficulty badge
  Start Cooking button
```

---

## Phase 19: Profile Screen

**Route:** `/profile`

### Layout (from design)
```
Avatar + Name + Title ("Food Lover & Home Chef")
Stats row: Recipes Saved | Recipes Cooked | Collections
Achievements badges (horizontal scroll)
Progress bar: Cooking Level (320 / 500 XP)
Menu items:
  Settings →
  Notifications →
  Dark Mode (toggle)
  Language → English
```

### Data
- `user_profile_model.dart` — name, avatar_url, cooking_level, xp, stats
- `user_repository.dart` — `fetchProfile(userId)`, `updateProfile(...)`, `uploadAvatar(file)`

---

## Phase 20: Notifications Screen

**Route:** `/notifications`

### Data
- `notifications` table in Supabase with `user_id`, `type`, `title`, `body`, `is_read`, `created_at`, `route`, `entity_id`
- Supabase Realtime stream for unread count badge on bottom nav

### Types
`recipe_suggestion`, `weekly_plan_reminder`, `cooking_reminder`, `system`, `achievement`

---

## Phase 21: Settings Screen

**Route:** `/settings`

- Dark mode toggle (persists via ThemeCubit → SecureStorage)
- Language picker (English — extensible via ARB)
- Notification preferences
- Account: Change password, Delete account
- About: App version, Terms, Privacy Policy

---

## Phase 22: Polish & Production

- [ ] Supabase Row Level Security audit on all tables
- [ ] Implement deep linking for recipe sharing (`/recipe/:id`)
- [ ] Add offline caching via `hive` or `drift` for favorites and recent recipes
- [ ] Push notification integration (Supabase + Firebase Messaging)
- [ ] App icon and splash screen (`flutter_native_splash`, `flutter_launcher_icons`)
- [ ] Performance profiling (image lazy loading, shimmer on all async screens)
- [ ] Crashlytics integration
- [ ] Play Store / App Store submission checklist

---

## Supabase Database Schema Summary

```sql
-- profiles (extends auth.users)
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  name text,
  avatar_url text,
  cooking_level text default 'beginner',
  xp int default 0,
  created_at timestamptz default now()
);

-- recipes
create table recipes (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  image_url text,
  description text,
  cook_time_minutes int,
  calories int,
  servings int,
  difficulty text,
  tags text[],
  category_id uuid references categories(id),
  user_id uuid references auth.users,
  source text default 'curated',   -- 'curated' | 'ai_generated' | 'user'
  is_published boolean default true,
  created_at timestamptz default now()
);

-- favorites
create table favorites (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade,
  recipe_id uuid references recipes(id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, recipe_id)
);

-- meal_plans
create table meal_plans (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade,
  recipe_id uuid references recipes(id),
  plan_date date not null,
  meal_type text not null,  -- 'breakfast' | 'lunch' | 'dinner'
  created_at timestamptz default now()
);

-- shopping_list
create table shopping_list (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade,
  name text not null,
  quantity text,
  category text,
  is_checked boolean default false,
  created_at timestamptz default now()
);

-- categories
create table categories (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  icon_url text,
  recipe_count int default 0
);

-- notifications
create table notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade,
  type text,
  title text,
  body text,
  is_read boolean default false,
  route text,
  entity_id text,
  created_at timestamptz default now()
);
```

Enable RLS on all tables. Enable Realtime on `shopping_list`, `meal_plans`, `notifications`.

---

## Quick Build Order Summary

| Phase | What | Output |
|---|---|---|
| 1 | pubspec.yaml | Dependencies ready |
| 2 | Folder structure | Empty scaffold |
| 3 | Core infra | Result, Supabase, DI, Theme |
| 4 | Shared widgets | Reusable UI atoms |
| 5 | Common cubits | App-wide state |
| 6 | Auth module | Login / Sign Up working |
| 7 | Routing | All routes, auth guard |
| 8 | Env + l10n + assets | Keys, strings, images |
| 9 | Build runner | Code generated ✅ |
| 10 | Splash + Onboarding | First impression ✅ |
| 11–19 | Feature screens | Full app ✅ |
| 20–21 | Notifications + Settings | Complete ✅ |
| 22 | Polish + production | Ship ready 🚀 |
