import 'package:equatable/equatable.dart';

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

class ChangeFavoritesTab extends FavoritesEvent {
  final int index;
  const ChangeFavoritesTab(this.index);

  @override
  List<Object?> get props => [index];
}

class CreateCollection extends FavoritesEvent {
  final String name;
  const CreateCollection(this.name);

  @override
  List<Object?> get props => [name];
}
