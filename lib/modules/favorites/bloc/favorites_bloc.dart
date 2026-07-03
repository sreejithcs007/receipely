import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc()
      : super(const FavoritesState(
          selectedTabIndex: 0,
          favorites: [
            FavoriteRecipeItem(
              id: 'fav_oatmeal',
              title: 'Blueberry Banana Oatmeal',
              imageUrl: AppImages.heroBanner,
              cookTime: '15 min',
              difficulty: 'Easy',
            ),
            FavoriteRecipeItem(
              id: 'fav_salmon',
              title: 'Honey Garlic Salmon',
              imageUrl: AppImages.heroBanner,
              cookTime: '25 min',
              difficulty: 'Medium',
            ),
            FavoriteRecipeItem(
              id: 'fav_pasta',
              title: 'Creamy Parmesan Pasta',
              imageUrl: AppImages.heroBanner,
              cookTime: '20 min',
              difficulty: 'Easy',
            ),
            FavoriteRecipeItem(
              id: 'fav_tacos',
              title: 'Ground Beef Tacos',
              imageUrl: AppImages.heroBanner,
              cookTime: '20 min',
              difficulty: 'Easy',
            ),
          ],
          collections: [
            FavoriteCollectionItem(
              id: 'col_breakfast',
              name: 'Breakfast Ideas',
              recipeCount: 12,
              badgeHexColor: 0xFFFFF2D9, // light warm yellow
            ),
            FavoriteCollectionItem(
              id: 'col_quick_din',
              name: 'Quick Dinners',
              recipeCount: 18,
              badgeHexColor: 0xFFEAF5E3, // light green
            ),
          ],
          isLoading: false,
        )) {
    on<LoadFavoritesPage>(_onLoadFavoritesPage);
    on<ToggleFavoriteItemState>(_onToggleFavoriteItemState);
    on<ChangeFavoritesTab>(_onChangeFavoritesTab);
    on<CreateCollection>(_onCreateCollection);
  }

  void _onLoadFavoritesPage(LoadFavoritesPage event, Emitter<FavoritesState> emit) {
    emit(state.copyWith(isLoading: false));
  }

  void _onToggleFavoriteItemState(ToggleFavoriteItemState event, Emitter<FavoritesState> emit) {
    final updated = List<FavoriteRecipeItem>.from(state.favorites);
    final exists = updated.any((r) => r.id == event.recipeId);

    if (exists) {
      updated.removeWhere((r) => r.id == event.recipeId);
    }

    emit(state.copyWith(favorites: updated));
  }

  void _onChangeFavoritesTab(ChangeFavoritesTab event, Emitter<FavoritesState> emit) {
    emit(state.copyWith(selectedTabIndex: event.index));
  }

  void _onCreateCollection(CreateCollection event, Emitter<FavoritesState> emit) {
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
