import '../datasources/supabase_data_source.dart';
import '../models/category_model.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  final SupabaseDataSource _dataSource;

  RecipeRepository(this._dataSource);

  Future<List<CategoryModel>> getCategories() async {
    return await _dataSource.getCategories();
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
    return await _dataSource.getRecipes(
      query: query,
      category: category,
      cuisine: cuisine,
      difficulty: difficulty,
      maxTimeMin: maxTimeMin,
      maxCalories: maxCalories,
      minRating: minRating,
      mealType: mealType,
      dietary: dietary,
      sortBy: sortBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getSearchSuggestions(
    String query, {
    int limit = 8,
  }) async {
    return await _dataSource.getSearchSuggestions(query, limit: limit);
  }

  Future<List<String>> getTrendingSearches({
    String window = 'weekly',
    int limit = 10,
  }) async {
    return await _dataSource.getTrendingSearches(window: window, limit: limit);
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
    await _dataSource.logSearchEvent(
      userId: userId,
      query: query,
      resultsCount: resultsCount,
      hadResults: hadResults,
      searchDurationMs: searchDurationMs,
      clickedRecipeId: clickedRecipeId,
      sortBy: sortBy,
      filtersApplied: filtersApplied,
    );
  }

  Future<List<RecipeModel>> getFeaturedRecipes() async {
    return await _dataSource.getFeaturedRecipes();
  }

  Future<List<RecipeModel>> getTrendingRecipes() async {
    print('hello == i am at line 79 of receipe repos');
    return await _dataSource.getTrendingRecipes();
  }

  Future<List<String>> getRecipeIngredients(String recipeId) async {
    return await _dataSource.getRecipeIngredients(recipeId);
  }

  Future<List<String>> getRecipeSteps(String recipeId) async {
    return await _dataSource.getRecipeSteps(recipeId);
  }

  Future<List<RecipeModel>> getRecentlyViewed(String userId) async {
    return await _dataSource.getRecentlyViewed(userId);
  }

  Future<void> addRecentlyViewed(String userId, String recipeId) async {
    await _dataSource.addRecentlyViewed(userId, recipeId);
  }
}
