import 'dart:io' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/recipe_model.dart';
import '../models/user_profile_model.dart';

class SupabaseDataSource {
  final SupabaseClient _client;

  SupabaseDataSource(this._client);

  // ── Authentication ──────────────────────────────────────────────────
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({required String email, required String password, required String name}) async {
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
    return (response as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<List<RecipeModel>> getRecipes({String? query, String? category}) async {
    var request = _client.from('recipes').select();
    
    if (category != null && category.isNotEmpty) {
      final catResp = await _client.from('categories').select('id').eq('name', category).maybeSingle();
      if (catResp != null) {
        final catId = catResp['id'] as String;
        final junctions = await _client.from('recipe_categories').select('recipe_id').eq('category_id', catId);
        final recipeIds = (junctions as List).map((j) => j['recipe_id'] as String).toList();
        if (recipeIds.isNotEmpty) {
          request = request.inFilter('id', recipeIds);
        } else {
          return [];
        }
      }
    }

    if (query != null && query.isNotEmpty) {
      request = request.ilike('title', '%$query%');
    }

    final response = await request;
    return (response as List).map((json) => RecipeModel.fromJson(json)).toList();
  }

  Future<List<RecipeModel>> getFeaturedRecipes() async {
    final response = await _client.from('recipes').select().eq('is_featured', true);
    return (response as List).map((json) => RecipeModel.fromJson(json)).toList();
  }

  Future<List<RecipeModel>> getTrendingRecipes() async {
    final response = await _client.from('recipes').select().eq('is_trending', true);
    return (response as List).map((json) => RecipeModel.fromJson(json)).toList();
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
    return (response as List).map((json) => json['step_content'] as String).toList();
  }

  // ── User Specific Profile ───────────────────────────────────────────
  Future<UserProfileModel> getUserProfile(String userId) async {
    final response = await _client.from('users').select().eq('id', userId).single();
    return UserProfileModel.fromJson(response);
  }

  Future<void> updateUserProfile(String userId, {required String name, required String title}) async {
    await _client.from('users').update({
      'name': name,
      'chef_level': title,
    }).eq('id', userId);
  }

  Future<String?> updateUserAvatar(String userId, String filePath) async {
    final fileBytes = await io.File(filePath).readAsBytes();
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('user-avatars').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    
    final avatarUrl = _client.storage.from('user-avatars').getPublicUrl(fileName);
    
    await _client.from('users').update({
      'avatar_url': avatarUrl,
    }).eq('id', userId);
    
    return avatarUrl;
  }

  // ── Favorites ────────────────────────────────────────────────────────
  Future<List<RecipeModel>> getFavorites(String userId) async {
    final response = await _client.from('favorites').select('recipes(*)').eq('user_id', userId);
    return (response as List).map((json) => RecipeModel.fromJson(json['recipes'])).toList();
  }

  Future<void> addFavorite(String userId, String recipeId) async {
    await _client.from('favorites').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
    });
  }

  Future<void> removeFavorite(String userId, String recipeId) async {
    await _client.from('favorites').delete().eq('user_id', userId).eq('recipe_id', recipeId);
  }

  // ── Recently Viewed ──────────────────────────────────────────────────
  Future<List<RecipeModel>> getRecentlyViewed(String userId) async {
    final response = await _client
        .from('recently_viewed')
        .select('recipes(*)')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(10);
    return (response as List).map((json) => RecipeModel.fromJson(json['recipes'])).toList();
  }

  Future<void> addRecentlyViewed(String userId, String recipeId) async {
    await _client.from('recently_viewed').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
      'viewed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ── Search History ───────────────────────────────────────────────────
  Future<List<String>> getSearchHistory(String userId) async {
    final response = await _client
        .from('search_history')
        .select('query')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10);
    return (response as List).map((json) => json['query'] as String).toList();
  }

  Future<void> addSearchHistory(String userId, String query) async {
    await _client.from('search_history').insert({
      'user_id': userId,
      'query': query,
    });
  }

  Future<void> clearSearchHistory(String userId) async {
    await _client.from('search_history').delete().eq('user_id', userId);
  }

  // ── Preferences ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    final response = await _client.from('user_preferences').select().eq('user_id', userId).maybeSingle();
    return response ?? {
      'push_notifications': true,
      'email_newsletters': false,
      'active_theme': 'system'
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
}
