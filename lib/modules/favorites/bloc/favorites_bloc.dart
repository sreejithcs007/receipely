import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/data/models/recipe_model.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final UserRepository _userRepository;

  FavoritesBloc(this._userRepository)
      : super(const FavoritesState(
          favorites: [],
          sortType: FavoritesSortType.latestToOldest,
          isLoading: false,
        )) {
    on<LoadFavoritesPage>(_onLoadFavoritesPage);
    on<ToggleFavoriteItemState>(_onToggleFavoriteItemState);
    on<SortFavorites>(_onSortFavorites);
  }

  Future<void> _onLoadFavoritesPage(LoadFavoritesPage event, Emitter<FavoritesState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        final favoritesData = await _userRepository.getFavoritesWithDate(user.id);
        final favList = favoritesData.map((item) {
          final recipeJson = item['recipes'] as Map<String, dynamic>;
          final r = RecipeModel.fromJson(recipeJson);
          final createdAtStr = item['created_at'] as String;
          return FavoriteRecipeItem(
            id: r.id,
            title: r.title,
            imageUrl: r.imageUrl,
            cookTime: r.cookTime,
            difficulty: r.difficulty,
            favoritedAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
          );
        }).toList();

        final sorted = _sortRecipes(favList, state.sortType);

        emit(state.copyWith(
          favorites: sorted,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onToggleFavoriteItemState(ToggleFavoriteItemState event, Emitter<FavoritesState> emit) async {
    final user = _userRepository.getCurrentUser();
    if (user != null) {
      final updated = List<FavoriteRecipeItem>.from(state.favorites);
      updated.removeWhere((r) => r.id == event.recipeId);
      emit(state.copyWith(favorites: updated));
      try {
        await _userRepository.removeFavorite(user.id, event.recipeId);
      } catch (_) {}
    }
  }

  void _onSortFavorites(SortFavorites event, Emitter<FavoritesState> emit) {
    final sorted = _sortRecipes(state.favorites, event.sortType);
    emit(state.copyWith(
      sortType: event.sortType,
      favorites: sorted,
    ));
  }

  List<FavoriteRecipeItem> _sortRecipes(List<FavoriteRecipeItem> items, FavoritesSortType sortType) {
    final sorted = List<FavoriteRecipeItem>.from(items);
    switch (sortType) {
      case FavoritesSortType.latestToOldest:
        sorted.sort((a, b) => b.favoritedAt.compareTo(a.favoritedAt));
        break;
      case FavoritesSortType.oldestToLatest:
        sorted.sort((a, b) => a.favoritedAt.compareTo(b.favoritedAt));
        break;
      case FavoritesSortType.alphabeticalAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case FavoritesSortType.alphabeticalZA:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }
    return sorted;
  }
}
