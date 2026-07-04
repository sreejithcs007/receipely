import 'package:equatable/equatable.dart';

class RecipeSearchResult extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String rating;
  final String cookTime;
  final String calories;
  final String cuisine; // for filters
  final String diet;    // for filters

  const RecipeSearchResult({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.cookTime,
    required this.calories,
    this.cuisine = '',
    this.diet = '',
  });

  @override
  List<Object?> get props => [id, title, imageUrl, rating, cookTime, calories, cuisine, diet];
}

class SearchState extends Equatable {
  final String query;
  final List<String> recentSearches;
  final String? cuisineFilter;
  final String? dietFilter;
  final String? timeFilter;
  final List<RecipeSearchResult> results;
  final List<String> favoriteRecipeIds;
  final bool isLoading;

  const SearchState({
    required this.query,
    required this.recentSearches,
    this.cuisineFilter,
    this.dietFilter,
    this.timeFilter,
    required this.results,
    required this.favoriteRecipeIds,
    required this.isLoading,
  });

  SearchState copyWith({
    String? query,
    List<String>? recentSearches,
    String? Function()? cuisineFilter,
    String? Function()? dietFilter,
    String? Function()? timeFilter,
    List<RecipeSearchResult>? results,
    List<String>? favoriteRecipeIds,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      cuisineFilter: cuisineFilter != null ? cuisineFilter() : this.cuisineFilter,
      dietFilter: dietFilter != null ? dietFilter() : this.dietFilter,
      timeFilter: timeFilter != null ? timeFilter() : this.timeFilter,
      results: results ?? this.results,
      favoriteRecipeIds: favoriteRecipeIds ?? this.favoriteRecipeIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        query,
        recentSearches,
        cuisineFilter,
        dietFilter,
        timeFilter,
        results,
        favoriteRecipeIds,
        isLoading,
      ];
}
