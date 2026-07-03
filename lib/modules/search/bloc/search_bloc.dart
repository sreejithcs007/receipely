import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  // All recipes in the app (Mock Data)
  static final List<RecipeSearchResult> _allRecipes = [
    const RecipeSearchResult(
      id: 'r_pasta',
      title: 'Creamy Garlic Parmesan Pasta',
      imageUrl: AppImages.heroBanner,
      rating: '4.8',
      cookTime: '25 min',
      calories: '560 cal',
      cuisine: 'Italian',
      diet: 'Vegetarian',
    ),
    const RecipeSearchResult(
      id: 'r_salad',
      title: 'Greek Chicken Salad',
      imageUrl: AppImages.heroBanner,
      rating: '4.7',
      cookTime: '20 min',
      calories: '380 cal',
      cuisine: 'Greek',
      diet: 'Low Carb',
    ),
    const RecipeSearchResult(
      id: 'r_smoothie',
      title: 'Berry Blast Smoothie',
      imageUrl: AppImages.heroBanner,
      rating: '4.9',
      cookTime: '5 min',
      calories: '210 cal',
      cuisine: 'American',
      diet: 'Vegan',
    ),
    const RecipeSearchResult(
      id: 'r_curry',
      title: 'Coconut Chickpea Curry',
      imageUrl: AppImages.heroBanner,
      rating: '4.8',
      cookTime: '30 min',
      calories: '420 cal',
      cuisine: 'Indian',
      diet: 'Vegan',
    ),
  ];

  SearchBloc()
      : super(const SearchState(
          query: '',
          recentSearches: ['pasta', 'salad', 'smoothie'],
          results: [],
          isLoading: false,
        )) {
    on<LoadSearchPage>(_onLoadSearchPage);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<AddRecentSearch>(_onAddRecentSearch);
    on<RemoveRecentSearch>(_onRemoveRecentSearch);
    on<ClearRecentSearches>(_onClearRecentSearches);
    on<SelectFilter>(_onSelectFilter);
  }

  void _onLoadSearchPage(LoadSearchPage event, Emitter<SearchState> emit) {
    emit(state.copyWith(
      results: _filterRecipes(state.query, state.cuisineFilter, state.dietFilter, state.timeFilter),
    ));
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    emit(state.copyWith(
      query: event.query,
      results: _filterRecipes(event.query, state.cuisineFilter, state.dietFilter, state.timeFilter),
    ));
  }

  void _onAddRecentSearch(AddRecentSearch event, Emitter<SearchState> emit) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) return;
    
    final updated = List<String>.from(state.recentSearches);
    updated.remove(query); // remove duplicate
    updated.insert(0, query); // put at front
    if (updated.length > 5) updated.removeLast(); // limit size
    
    emit(state.copyWith(recentSearches: updated));
  }

  void _onRemoveRecentSearch(RemoveRecentSearch event, Emitter<SearchState> emit) {
    final updated = List<String>.from(state.recentSearches)
      ..remove(event.query.toLowerCase());
    emit(state.copyWith(recentSearches: updated));
  }

  void _onClearRecentSearches(ClearRecentSearches event, Emitter<SearchState> emit) {
    emit(state.copyWith(recentSearches: const []));
  }

  void _onSelectFilter(SelectFilter event, Emitter<SearchState> emit) {
    String? cuisine = state.cuisineFilter;
    String? diet = state.dietFilter;
    String? time = state.timeFilter;

    if (event.filterType == 'cuisine') {
      cuisine = event.value;
    } else if (event.filterType == 'diet') {
      diet = event.value;
    } else if (event.filterType == 'time') {
      time = event.value;
    }

    emit(state.copyWith(
      cuisineFilter: () => cuisine,
      dietFilter: () => diet,
      timeFilter: () => time,
      results: _filterRecipes(state.query, cuisine, diet, time),
    ));
  }

  List<RecipeSearchResult> _filterRecipes(
    String query,
    String? cuisine,
    String? diet,
    String? time,
  ) {
    return _allRecipes.where((recipe) {
      // 1. Text Query Filter
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesTitle = recipe.title.toLowerCase().contains(q);
        final matchesCuisine = recipe.cuisine.toLowerCase().contains(q);
        final matchesDiet = recipe.diet.toLowerCase().contains(q);
        if (!matchesTitle && !matchesCuisine && !matchesDiet) {
          return false;
        }
      }

      // 2. Cuisine Filter
      if (cuisine != null && recipe.cuisine != cuisine) {
        return false;
      }

      // 3. Diet Filter
      if (diet != null && recipe.diet != diet) {
        return false;
      }

      // 4. Time Filter
      if (time != null) {
        final minutes = int.tryParse(recipe.cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (time == 'Under 15 min' && minutes >= 15) return false;
        if (time == 'Under 30 min' && minutes >= 30) return false;
      }

      return true;
    }).toList();
  }
}
