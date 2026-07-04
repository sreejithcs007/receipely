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
          favoriteRecipeIds: [],
          isLoading: false,
        )) {
    on<LoadSearchPage>(_onLoadSearchPage);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<AddRecentSearch>(_onAddRecentSearch);
    on<RemoveRecentSearch>(_onRemoveRecentSearch);
    on<ClearRecentSearches>(_onClearRecentSearches);
    on<SelectFilter>(_onSelectFilter);
    on<ToggleFavoriteRecipeSearchResult>(_onToggleFavoriteRecipeSearchResult);
  }

  Future<void> _onLoadSearchPage(LoadSearchPage event, Emitter<SearchState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = _userRepository.getCurrentUser();
      List<String> searches = [];
      List<String> favoriteRecipeIds = [];
      if (user != null) {
        searches = await _userRepository.getSearchHistory(user.id);
        try {
          final favorites = await _userRepository.getFavorites(user.id);
          favoriteRecipeIds = favorites.map((r) => r.id).toList();
        } catch (_) {}
      }
      
      final recipes = await _recipeRepository.getRecipes();
      final results = _mapToSearchResults(recipes);

      emit(state.copyWith(
        recentSearches: searches,
        results: results,
        favoriteRecipeIds: favoriteRecipeIds,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onSearchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    emit(state.copyWith(query: event.query, isLoading: true));
    final stopwatch = Stopwatch()..start();
    try {
      int? maxTimeMin;
      if (state.timeFilter == 'Under 15 min') {
        maxTimeMin = 15;
      } else if (state.timeFilter == 'Under 30 min') {
        maxTimeMin = 30;
      }

      final recipes = (event.query.toLowerCase() == 'trending')
          ? await _recipeRepository.getTrendingRecipes()
          : await _recipeRepository.getRecipes(
              query: event.query,
              cuisine: state.cuisineFilter,
              dietary: state.dietFilter != null ? [state.dietFilter!] : null,
              maxTimeMin: maxTimeMin,
            );
      final results = _mapToSearchResults(recipes);
      emit(state.copyWith(results: results, isLoading: false));

      // Log search analytics event
      stopwatch.stop();
      final user = _userRepository.getCurrentUser();
      await _recipeRepository.logSearchEvent(
        userId: user?.id,
        query: event.query,
        resultsCount: results.length,
        hadResults: results.isNotEmpty,
        searchDurationMs: stopwatch.elapsedMilliseconds,
        filtersApplied: {
          'cuisine': state.cuisineFilter,
          'diet': state.dietFilter,
          'time': state.timeFilter,
        },
      );
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
    final updated = List<String>.from(state.recentSearches)..remove(event.query);
    emit(state.copyWith(recentSearches: updated));

    if (user != null) {
      try {
        await _userRepository.deleteSearchHistoryQuery(user.id, event.query);
      } catch (_) {}
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

    final stopwatch = Stopwatch()..start();
    try {
      int? maxTimeMin;
      if (time == 'Under 15 min') {
        maxTimeMin = 15;
      } else if (time == 'Under 30 min') {
        maxTimeMin = 30;
      }

      final recipes = (state.query.toLowerCase() == 'trending')
          ? await _recipeRepository.getTrendingRecipes()
          : await _recipeRepository.getRecipes(
              query: state.query,
              cuisine: cuisine,
              dietary: diet != null ? [diet] : null,
              maxTimeMin: maxTimeMin,
            );
      final results = _mapToSearchResults(recipes);
      emit(state.copyWith(results: results, isLoading: false));

      // Log search analytics event
      stopwatch.stop();
      final user = _userRepository.getCurrentUser();
      await _recipeRepository.logSearchEvent(
        userId: user?.id,
        query: state.query,
        resultsCount: results.length,
        hadResults: results.isNotEmpty,
        searchDurationMs: stopwatch.elapsedMilliseconds,
        filtersApplied: {
          'cuisine': cuisine,
          'diet': diet,
          'time': time,
        },
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  List<RecipeSearchResult> _mapToSearchResults(List<RecipeModel> recipes) {
    return recipes.map((r) => RecipeSearchResult(
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

  Future<void> _onToggleFavoriteRecipeSearchResult(
    ToggleFavoriteRecipeSearchResult event,
    Emitter<SearchState> emit,
  ) async {
    final isFavorited = state.favoriteRecipeIds.contains(event.recipeId);
    final updatedFavorites = List<String>.from(state.favoriteRecipeIds);

    if (isFavorited) {
      updatedFavorites.remove(event.recipeId);
    } else {
      updatedFavorites.add(event.recipeId);
    }

    emit(state.copyWith(favoriteRecipeIds: updatedFavorites));

    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        if (isFavorited) {
          await _userRepository.removeFavorite(user.id, event.recipeId);
        } else {
          await _userRepository.addFavorite(user.id, event.recipeId);
        }
      } catch (_) {}
    }
  }
}
