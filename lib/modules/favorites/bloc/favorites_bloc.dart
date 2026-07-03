import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final UserRepository _userRepository;

  FavoritesBloc(this._userRepository)
      : super(const FavoritesState(
          selectedTabIndex: 0,
          favorites: [],
          collections: [],
          isLoading: false,
        )) {
    on<LoadFavoritesPage>(_onLoadFavoritesPage);
    on<ToggleFavoriteItemState>(_onToggleFavoriteItemState);
    on<ChangeFavoritesTab>(_onChangeFavoritesTab);
    on<CreateCollection>(_onCreateCollection);
  }

  Future<void> _onLoadFavoritesPage(LoadFavoritesPage event, Emitter<FavoritesState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        final favorites = await _userRepository.getFavorites(user.id);
        final favList = favorites.map((r) => FavoriteRecipeItem(
          id: r.id,
          title: r.title,
          imageUrl: r.imageUrl,
          cookTime: r.cookTime,
          difficulty: r.difficulty,
        )).toList();

        final collectionsList = [
          const FavoriteCollectionItem(
            id: 'col_breakfast',
            name: 'Breakfast Ideas',
            recipeCount: 12,
            badgeHexColor: 0xFFFFF2D9,
          ),
          const FavoriteCollectionItem(
            id: 'col_quick_din',
            name: 'Quick Dinners',
            recipeCount: 18,
            badgeHexColor: 0xFFEAF5E3,
          ),
        ];

        emit(state.copyWith(
          favorites: favList,
          collections: collectionsList,
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

  void _onChangeFavoritesTab(ChangeFavoritesTab event, Emitter<FavoritesState> emit) {
    emit(state.copyWith(selectedTabIndex: event.index));
  }

  Future<void> _onCreateCollection(CreateCollection event, Emitter<FavoritesState> emit) async {
    final updated = List<FavoriteCollectionItem>.from(state.collections)
      ..add(FavoriteCollectionItem(
        id: 'col_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        recipeCount: 0,
        badgeHexColor: 0xFFFAF0F5,
      ));
    emit(state.copyWith(collections: updated));
  }
}
