import 'package:equatable/equatable.dart';
import 'favorites_state.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavoritesPage extends FavoritesEvent {}

class ToggleFavoriteItemState extends FavoritesEvent {
  final String recipeId;
  const ToggleFavoriteItemState(this.recipeId);

  @override
  List<Object?> get props => [recipeId];
}

class SortFavorites extends FavoritesEvent {
  final FavoritesSortType sortType;
  const SortFavorites(this.sortType);

  @override
  List<Object?> get props => [sortType];
}
