import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class ToggleFavoriteRecipe extends HomeEvent {
  final String recipeId;
  const ToggleFavoriteRecipe(this.recipeId);

  @override
  List<Object?> get props => [recipeId];
}
