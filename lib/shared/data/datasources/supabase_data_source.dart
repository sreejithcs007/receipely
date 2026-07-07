import 'dart:io' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/recipe_model.dart';
import '../models/user_profile_model.dart';

class SupabaseDataSource {
  final SupabaseClient _client;

  SupabaseDataSource(this._client);

  // ── Authentication ──────────────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // ── Categories & Recipes ─────────────────────────────────────────────
  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.from('categories').select();
    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  Future<List<RecipeModel>> getRecipes({
    String? query,
    String? category,
    String? cuisine,
    String? difficulty,
    int? maxTimeMin,
    int? maxCalories,
    double? minRating,
    String? mealType,
    List<String>? dietary,
    String sortBy = 'relevance',
    int limit = 20,
    int offset = 0,
  }) async {
    final hasFilters =
        (cuisine != null && cuisine.isNotEmpty) ||
        (difficulty != null && difficulty.isNotEmpty) ||
        maxTimeMin != null ||
        maxCalories != null ||
        minRating != null ||
        (mealType != null && mealType.isNotEmpty) ||
        (dietary != null && dietary.isNotEmpty);

    if ((query != null && query.isNotEmpty) || hasFilters) {
      String? categoryId;
      if (category != null && category.isNotEmpty) {
        final catResp = await _client
            .from('categories')
            .select('id')
            .eq('name', category)
            .maybeSingle();
        if (catResp != null) {
          categoryId = catResp['id'] as String;
        }
      }

      final response = await _client.rpc(
        'search_recipes',
        params: {
          'p_query': query,
          'p_category_id': categoryId,
          'p_cuisine': cuisine,
          'p_difficulty': difficulty,
          'p_max_time_min': maxTimeMin,
          'p_max_calories': maxCalories,
          'p_min_rating': minRating,
          'p_meal_type': mealType,
          'p_dietary': dietary,
          'p_sort_by': sortBy,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      var list = (response as List)
          .map((json) => RecipeModel.fromJson(json))
          .toList();

      if (list.isEmpty && query != null && query.trim().isNotEmpty) {
        final fallbackResponse = await _client
            .from('recipes')
            .select()
            .ilike('title', '%${query.trim()}%')
            .isFilter('deleted_at', null)
            .limit(limit);
        list = (fallbackResponse as List)
            .map((json) => RecipeModel.fromJson(json))
            .toList();
      }

      return list;
    }

    var request = _client.from('recipes').select().isFilter('deleted_at', null);

    if (category != null && category.isNotEmpty) {
      final catResp = await _client
          .from('categories')
          .select('id')
          .eq('name', category)
          .maybeSingle();
      if (catResp != null) {
        final catId = catResp['id'] as String;
        final junctions = await _client
            .from('recipe_categories')
            .select('recipe_id')
            .eq('category_id', catId);
        final recipeIds = (junctions as List)
            .map((j) => j['recipe_id'] as String)
            .toList();
        if (recipeIds.isNotEmpty) {
          request = request.inFilter('id', recipeIds);
        } else {
          return [];
        }
      }
    }

    final response = await request;
    return (response as List)
        .map((json) => RecipeModel.fromJson(json))
        .toList();
  }

  Future<List<RecipeModel>> getFeaturedRecipes() async {
    final response = await _client
        .from('recipes')
        .select()
        .eq('is_featured', true)
        .isFilter('deleted_at', null);
    return (response as List)
        .map((json) => RecipeModel.fromJson(json))
        .toList();
  }

  Future<List<RecipeModel>> getTrendingRecipes() async {
    // final response = await _client.from('recipes').select().eq('is_trending', true);
    final response = await _client
        .from('recipes')
        .select()
        .eq('is_trending', true)
        .isFilter('deleted_at', null);
    return (response as List)
        .map((json) => RecipeModel.fromJson(json))
        .toList();
  }

  Future<List<String>> getRecipeIngredients(String recipeId) async {
    final response = await _client
        .from('recipe_ingredients')
        .select('name')
        .eq('recipe_id', recipeId)
        .order('index', ascending: true);
    return (response as List).map((json) => json['name'] as String).toList();
  }

  Future<List<String>> getRecipeSteps(String recipeId) async {
    final response = await _client
        .from('recipe_steps')
        .select('step_content')
        .eq('recipe_id', recipeId)
        .order('step_number', ascending: true);
    return (response as List)
        .map((json) => json['step_content'] as String)
        .toList();
  }

  // ── User Specific Profile ───────────────────────────────────────────
  Future<UserProfileModel> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return UserProfileModel.fromJson(response);
  }

  Future<void> updateUserProfile(
    String userId, {
    required String name,
    required String title,
  }) async {
    await _client
        .from('users')
        .update({'name': name, 'chef_level': title})
        .eq('id', userId);
  }

  Future<void> createUserProfileIfMissing(String userId, String email, String name) async {
    await _client.from('users').upsert({
      'id': userId,
      'email': email,
      'name': name,
      'chef_level': 'Home Chef',
      'avatar_url': 'user-avatars/default.png',
    });
  }

  Future<String?> updateUserAvatar(String userId, String filePath) async {
    final fileBytes = await io.File(filePath).readAsBytes();
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage
        .from('user-avatars')
        .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final avatarUrl = _client.storage
        .from('user-avatars')
        .getPublicUrl(fileName);

    await _client
        .from('users')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);

    return avatarUrl;
  }

  // ── Favorites ────────────────────────────────────────────────────────
  Future<List<RecipeModel>> getFavorites(String userId) async {
    final response = await _client
        .from('favorites')
        .select('recipes(*)')
        .eq('user_id', userId);
    return (response as List)
        .where((json) => json['recipes'] != null && json['recipes']['deleted_at'] == null)
        .map((json) => RecipeModel.fromJson(json['recipes'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getFavoritesWithDate(String userId) async {
    final response = await _client
        .from('favorites')
        .select('created_at, recipes(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .where((json) => json['recipes'] != null && json['recipes']['deleted_at'] == null)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }

  Future<void> addFavorite(String userId, String recipeId) async {
    await _client.from('favorites').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
    });
  }

  Future<void> removeFavorite(String userId, String recipeId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId);
  }

  // ── Recently Viewed ──────────────────────────────────────────────────
  Future<List<RecipeModel>> getRecentlyViewed(String userId) async {
    final response = await _client
        .from('recently_viewed')
        .select('recipes(*)')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(10);
    return (response as List)
        .where((json) => json['recipes'] != null && json['recipes']['deleted_at'] == null)
        .map((json) => RecipeModel.fromJson(json['recipes'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> addRecentlyViewed(String userId, String recipeId) async {
    await _client.from('recently_viewed').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
      'viewed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ── Search History & Advanced Search ─────────────────────────────────
  Future<List<String>> getSearchHistory(String userId) async {
    final response = await _client.rpc(
      'get_recent_searches',
      params: {'p_user_id': userId, 'p_limit': 10},
    );
    return (response as List).map((json) => json['query'] as String).toList();
  }

  Future<void> addSearchHistory(String userId, String query) async {
    await _client.rpc(
      'upsert_search_history',
      params: {'p_user_id': userId, 'p_query': query},
    );
  }

  Future<void> clearSearchHistory(String userId) async {
    await _client.rpc('clear_search_history', params: {'p_user_id': userId});
  }

  Future<void> deleteSearchHistoryQuery(String userId, String query) async {
    await _client
        .from('search_history')
        .delete()
        .eq('user_id', userId)
        .eq('query', query);
  }

  Future<List<Map<String, dynamic>>> getSearchSuggestions(
    String query, {
    int limit = 8,
  }) async {
    final response = await _client.rpc(
      'search_suggestions',
      params: {'p_query': query, 'p_limit': limit},
    );
    return (response as List)
        .map((json) => Map<String, dynamic>.from(json))
        .toList();
  }

  Future<List<String>> getTrendingSearches({
    String window = 'weekly',
    int limit = 10,
  }) async {
    final response = await _client.rpc(
      'get_trending_searches',
      params: {'p_window': window, 'p_limit': limit},
    );
    return (response as List).map((json) => json['query'] as String).toList();
  }

  Future<void> logSearchEvent({
    required String? userId,
    required String query,
    required int resultsCount,
    required bool hadResults,
    required int searchDurationMs,
    String? clickedRecipeId,
    String? sortBy,
    Map<String, dynamic>? filtersApplied,
  }) async {
    try {
      await _client.rpc(
        'log_search_event',
        params: {
          'p_user_id': userId,
          'p_query': query,
          'p_results_count': resultsCount,
          'p_had_results': hadResults,
          'p_search_duration_ms': searchDurationMs,
          'p_clicked_recipe_id': clickedRecipeId,
          'p_sort_by': sortBy,
          'p_filters_applied': filtersApplied,
        },
      );
    } catch (_) {}
  }

  // ── Preferences ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    final response = await _client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response ??
        {
          'push_notifications': true,
          'email_newsletters': false,
          'active_theme': 'system',
        };
  }

  Future<void> updateUserPreferences(
    String userId, {
    required bool pushNotifications,
    required bool emailNewsletters,
    required String activeTheme,
  }) async {
    await _client.from('user_preferences').upsert({
      'user_id': userId,
      'push_notifications': pushNotifications,
      'email_newsletters': emailNewsletters,
      'active_theme': activeTheme,
    });
  }

  Future<void> markRecipeAsCooked(String userId, String recipeId) async {
    final profile = await getUserProfile(userId);
    final newCount = profile.cookedCount + 1;

    await _client
        .from('users')
        .update({'cooked_count': newCount})
        .eq('id', userId);

    await _client.from('user_activity').insert({
      'user_id': userId,
      'activity_type': 'cook',
      'meta_data': {'recipe_id': recipeId},
    });
  }

  Future<List<RecipeModel>> getCookedRecipes(String userId) async {
    final response = await _client
        .from('user_activity')
        .select('meta_data')
        .eq('user_id', userId)
        .eq('activity_type', 'cook')
        .order('created_at', ascending: false);

    final list = response as List;
    if (list.isEmpty) return [];

    final recipeIds = list
        .map((item) {
          final meta = item['meta_data'];
          if (meta is Map) {
            return meta['recipe_id'] as String?;
          }
          return null;
        })
        .whereType<String>()
        .toSet()
        .toList();

    if (recipeIds.isEmpty) return [];

    final recipesResp = await _client
        .from('recipes')
        .select()
        .inFilter('id', recipeIds)
        .isFilter('deleted_at', null);

    final recipesList = (recipesResp as List)
        .map((json) => RecipeModel.fromJson(json))
        .toList();

    final orderedRecipes = <RecipeModel>[];
    for (final id in recipeIds) {
      final matches = recipesList.where((r) => r.id == id);
      if (matches.isNotEmpty) {
        orderedRecipes.add(matches.first);
      }
    }

    return orderedRecipes;
  }
}
