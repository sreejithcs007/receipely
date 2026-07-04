import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_data_source.dart';
import '../models/recipe_model.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  final SupabaseDataSource _dataSource;

  UserRepository(this._dataSource);

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _dataSource.signIn(email: email, password: password);
  }

  Future<AuthResponse> signUp({required String email, required String password, required String name}) async {
    return await _dataSource.signUp(email: email, password: password, name: name);
  }

  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  User? getCurrentUser() {
    return _dataSource.getCurrentUser();
  }

  Future<UserProfileModel> getUserProfile(String userId) async {
    return await _dataSource.getUserProfile(userId);
  }

  Future<void> createUserProfileIfMissing(String userId, String email, String name) async {
    await _dataSource.createUserProfileIfMissing(userId, email, name);
  }

  Future<void> updateUserProfile(String userId, {required String name, required String title}) async {
    await _dataSource.updateUserProfile(userId, name: name, title: title);
  }

  Future<String?> updateUserAvatar(String userId, String filePath) async {
    return await _dataSource.updateUserAvatar(userId, filePath);
  }

  Future<List<RecipeModel>> getFavorites(String userId) async {
    return await _dataSource.getFavorites(userId);
  }

  Future<List<Map<String, dynamic>>> getFavoritesWithDate(String userId) async {
    return await _dataSource.getFavoritesWithDate(userId);
  }

  Future<void> addFavorite(String userId, String recipeId) async {
    await _dataSource.addFavorite(userId, recipeId);
  }

  Future<void> removeFavorite(String userId, String recipeId) async {
    await _dataSource.removeFavorite(userId, recipeId);
  }

  Future<List<String>> getSearchHistory(String userId) async {
    return await _dataSource.getSearchHistory(userId);
  }

  Future<void> addSearchHistory(String userId, String query) async {
    await _dataSource.addSearchHistory(userId, query);
  }

  Future<void> clearSearchHistory(String userId) async {
    await _dataSource.clearSearchHistory(userId);
  }

  Future<void> deleteSearchHistoryQuery(String userId, String query) async {
    await _dataSource.deleteSearchHistoryQuery(userId, query);
  }

  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    return await _dataSource.getUserPreferences(userId);
  }

  Future<void> updateUserPreferences(
    String userId, {
    required bool pushNotifications,
    required bool emailNewsletters,
    required String activeTheme,
  }) async {
    await _dataSource.updateUserPreferences(
      userId,
      pushNotifications: pushNotifications,
      emailNewsletters: emailNewsletters,
      activeTheme: activeTheme,
    );
  }
}
