import 'package:equatable/equatable.dart';

class RecipeDetailState extends Equatable {
  final String recipeId;
  final String title;
  final String description;
  final String imageUrl;
  final String rating;
  final String reviews;
  final String cookTime;
  final String calories;
  final String servings;
  final List<String> ingredients;
  final List<bool> checkedIngredients;
  final List<String> steps;
  final bool isFavorite;
  final bool isSaved;
  final int selectedTabIndex;
  final bool isCooking;
  final int currentCookingStep;

  const RecipeDetailState({
    required this.recipeId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.cookTime,
    required this.calories,
    required this.servings,
    required this.ingredients,
    required this.checkedIngredients,
    required this.steps,
    required this.isFavorite,
    required this.isSaved,
    required this.selectedTabIndex,
    required this.isCooking,
    required this.currentCookingStep,
  });

  RecipeDetailState copyWith({
    String? recipeId,
    String? title,
    String? description,
    String? imageUrl,
    String? rating,
    String? reviews,
    String? cookTime,
    String? calories,
    String? servings,
    List<String>? ingredients,
    List<bool>? checkedIngredients,
    List<String>? steps,
    bool? isFavorite,
    bool? isSaved,
    int? selectedTabIndex,
    bool? isCooking,
    int? currentCookingStep,
  }) {
    return RecipeDetailState(
      recipeId: recipeId ?? this.recipeId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      cookTime: cookTime ?? this.cookTime,
      calories: calories ?? this.calories,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      checkedIngredients: checkedIngredients ?? this.checkedIngredients,
      steps: steps ?? this.steps,
      isFavorite: isFavorite ?? this.isFavorite,
      isSaved: isSaved ?? this.isSaved,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isCooking: isCooking ?? this.isCooking,
      currentCookingStep: currentCookingStep ?? this.currentCookingStep,
    );
  }

  @override
  List<Object?> get props => [
        recipeId,
        title,
        description,
        imageUrl,
        rating,
        reviews,
        cookTime,
        calories,
        servings,
        ingredients,
        checkedIngredients,
        steps,
        isFavorite,
        isSaved,
        selectedTabIndex,
        isCooking,
        currentCookingStep,
      ];
}
