# Meal Planner — Recipely

## Overview

The Meal Planner lets users assign recipes to specific days of the week across Breakfast, Lunch, and Dinner slots. It uses **Supabase Realtime** for live sync and **GoRouter** for in-planner navigation.

**Screen:** `meal_planner_screen.dart`  
**Module path:** `lib/modules/meal_planner/`

---

## Supabase Table

### `meal_plans`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | FK → `auth.users` |
| `recipe_id` | uuid | FK → `recipes` |
| `plan_date` | date | The planned date |
| `meal_type` | text | `breakfast`, `lunch`, `dinner` |
| `created_at` | timestamptz | Auto-set |

Enable **Realtime** on this table in the Supabase dashboard.

---

## Repository

```dart
class MealPlannerRepository {
  final SupabaseClient _client;

  MealPlannerRepository(this._client);

  /// Stream the current week's meal plan for the user.
  Stream<List<MealPlanModel>> watchWeeklyPlan({
    required String userId,
    required DateTime weekStart,
  }) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _client
        .from('meal_plans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .gte('plan_date', weekStart.toIso8601String().split('T').first)
        .lte('plan_date', weekEnd.toIso8601String().split('T').first)
        .map((rows) => rows.map(MealPlanModel.fromJson).toList());
  }

  Future<Result<void>> addMeal({
    required String userId,
    required String recipeId,
    required DateTime date,
    required String mealType,
  }) async {
    try {
      await _client.from('meal_plans').insert({
        'user_id': userId,
        'recipe_id': recipeId,
        'plan_date': date.toIso8601String().split('T').first,
        'meal_type': mealType,
      });
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.error(e.message);
    }
  }

  Future<Result<void>> removeMeal(String mealPlanId) async {
    try {
      await _client.from('meal_plans').delete().eq('id', mealPlanId);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.error(e.message);
    }
  }
}
```

---

## Cubit

Use `StreamSubscription` to listen to the realtime stream and emit updated state.

```dart
class MealPlannerCubit extends Cubit<MealPlannerState> {
  final MealPlannerRepository _repository;
  StreamSubscription? _subscription;
  DateTime _weekStart = _currentWeekStart();

  MealPlannerCubit(this._repository) : super(MealPlannerInitial());

  void loadWeek(String userId) {
    emit(MealPlannerLoading());
    _subscription?.cancel();
    _subscription = _repository
        .watchWeeklyPlan(userId: userId, weekStart: _weekStart)
        .listen(
          (plans) => emit(MealPlannerLoaded(plans: plans, weekStart: _weekStart)),
          onError: (e) => emit(MealPlannerError(e.toString())),
        );
  }

  void goToNextWeek(String userId) {
    _weekStart = _weekStart.add(const Duration(days: 7));
    loadWeek(userId);
  }

  void goToPreviousWeek(String userId) {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    loadWeek(userId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }
}
```

---

## UI Notes

- Show a horizontal week selector with Mon–Sun columns.
- Each day column has three slots: Breakfast, Lunch, Dinner.
- Filled slots show a mini `RecipeCard`. Empty slots show a `+ Add` button.
- Tapping `+ Add` opens a bottom sheet with a recipe search/picker.
- Tapping a filled slot navigates to `RecipeDetailRoute`.
- Long-pressing a filled slot shows a delete option.
- Week navigation (← →) replaces the current subscription with the new week's stream.

---

## Nutrition Summary

Display a weekly nutrition summary below the calendar by aggregating the `calories` field from each assigned recipe.

```dart
int get totalCalories => plans
    .map((p) => p.recipe.calories)
    .fold(0, (a, b) => a + b);
```
