import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/data/models/recipe_model.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;

  SearchBloc(this._recipeRepository, this._userRepository)
      : super(const SearchState(
          query: '',
          recentSearches: [],
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

  Future<void> _onLoadSearchPage(LoadSearchPage event, Emitter<SearchState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = _userRepository.getCurrentUser();
      List<String> searches = [];
      if (user != null) {
        searches = await _userRepository.getSearchHistory(user.id);
      }
      
      final recipes = await _recipeRepository.getRecipes();
      final results = _mapAndFilter(recipes, state.query, state.cuisineFilter, state.dietFilter, state.timeFilter);

      emit(state.copyWith(
        recentSearches: searches,
        results: results,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onSearchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    emit(state.copyWith(query: event.query, isLoading: true));
    try {
      final recipes = await _recipeRepository.getRecipes(query: event.query);
      final results = _mapAndFilter(recipes, event.query, state.cuisineFilter, state.dietFilter, state.timeFilter);
      emit(state.copyWith(results: results, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onAddRecentSearch(AddRecentSearch event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        await _userRepository.addSearchHistory(user.id, query);
        final searches = await _userRepository.getSearchHistory(user.id);
        emit(state.copyWith(recentSearches: searches));
      } catch (_) {}
    }
  }

  Future<void> _onRemoveRecentSearch(RemoveRecentSearch event, Emitter<SearchState> emit) async {
    final user = _userRepository.getCurrentUser();
    if (user != null) {
      // Just filter local for now
      final updated = List<String>.from(state.recentSearches)..remove(event.query);
      emit(state.copyWith(recentSearches: updated));
    }
  }

  Future<void> _onClearRecentSearches(ClearRecentSearches event, Emitter<SearchState> emit) async {
    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        await _userRepository.clearSearchHistory(user.id);
        emit(state.copyWith(recentSearches: const []));
      } catch (_) {}
    }
  }

  Future<void> _onSelectFilter(SelectFilter event, Emitter<SearchState> emit) async {
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
      isLoading: true,
    ));

    try {
      final recipes = await _recipeRepository.getRecipes(query: state.query);
      final results = _mapAndFilter(recipes, state.query, cuisine, diet, time);
      emit(state.copyWith(results: results, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  List<RecipeSearchResult> _mapAndFilter(
    List<RecipeModel> recipes,
    String query,
    String? cuisine,
    String? diet,
    String? time,
  ) {
    return recipes.where((recipe) {
      if (cuisine != null && cuisine.isNotEmpty) {
        final matchesCuisine = recipe.title.toLowerCase().contains(cuisine.toLowerCase()) || 
                             recipe.description.toLowerCase().contains(cuisine.toLowerCase()) ||
                             recipe.difficulty.toLowerCase() == cuisine.toLowerCase();
        if (!matchesCuisine) return false;
      }

      if (diet != null && diet.isNotEmpty) {
        final matchesDiet = recipe.title.toLowerCase().contains(diet.toLowerCase()) || 
                           recipe.description.toLowerCase().contains(diet.toLowerCase());
        if (!matchesDiet) return false;
      }

      if (time != null && time.isNotEmpty) {
        final minutes = int.tryParse(recipe.cookTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (time == 'Under 15 min' && minutes >= 15) return false;
        if (time == 'Under 30 min' && minutes >= 30) return false;
      }

      return true;
    }).map((r) => RecipeSearchResult(
      id: r.id,
      title: r.title,
      imageUrl: r.imageUrl,
      rating: r.rating.toString(),
      cookTime: r.cookTime,
      calories: r.calories,
      cuisine: r.difficulty,
      diet: r.servings,
    )).toList();
  }
}
