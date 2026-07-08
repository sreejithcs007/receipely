import 'package:equatable/equatable.dart';

abstract class RecipeDetailEvent extends Equatable {
  const RecipeDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecipeDetail extends RecipeDetailEvent {
  final String recipeId;
  const LoadRecipeDetail(this.recipeId);

  @override
  List<Object?> get props => [recipeId];
}

class ToggleIngredientCheck extends RecipeDetailEvent {
  final int index;
  const ToggleIngredientCheck(this.index);

  @override
  List<Object?> get props => [index];
}

class ToggleFavorite extends RecipeDetailEvent {}

class ChangeTab extends RecipeDetailEvent {
  final int index;
  const ChangeTab(this.index);

  @override
  List<Object?> get props => [index];
}

class StartCooking extends RecipeDetailEvent {}

class NextStep extends RecipeDetailEvent {}

class PrevStep extends RecipeDetailEvent {}

class CancelCooking extends RecipeDetailEvent {}

class CompleteCooking extends RecipeDetailEvent {}

class GoToStep extends RecipeDetailEvent {
  final int step;
  const GoToStep(this.step);

  @override
  List<Object?> get props => [step];
}

