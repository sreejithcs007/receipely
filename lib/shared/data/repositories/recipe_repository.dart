import '../datasources/supabase_data_source.dart';
import '../models/category_model.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  final SupabaseDataSource _dataSource;

  RecipeRepository(this._dataSource);

  Future<List<CategoryModel>> getCategories() async {
    return await _dataSource.getCategories();
  }

  Future<List<RecipeModel>> getRecipes({String? query, String? category}) async {
    return await _dataSource.getRecipes(query: query, category: category);
  }

  Future<List<RecipeModel>> getFeaturedRecipes() async {
    return await _dataSource.getFeaturedRecipes();
  }

  Future<List<RecipeModel>> getTrendingRecipes() async {
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
