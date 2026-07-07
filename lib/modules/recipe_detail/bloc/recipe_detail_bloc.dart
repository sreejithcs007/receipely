import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import 'recipe_detail_event.dart';
import 'recipe_detail_state.dart';

class RecipeDetailBloc extends Bloc<RecipeDetailEvent, RecipeDetailState> {
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;

  RecipeDetailBloc(this._recipeRepository, this._userRepository)
      : super(const RecipeDetailState(
          recipeId: '',
          title: 'Loading...',
          description: '',
          imageUrl: '',
          rating: '0.0',
          reviews: '0',
          cookTime: '0 min',
          calories: '0 kcal',
          servings: '1 serving',
          ingredients: [],
          checkedIngredients: [],
          steps: [],
          isFavorite: false,
          selectedTabIndex: 0,
          isCooking: false,
          currentCookingStep: 0,
        )) {
    on<LoadRecipeDetail>(_onLoadRecipeDetail);
    on<ToggleIngredientCheck>(_onToggleIngredientCheck);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ChangeTab>(_onTabChanged);
    on<StartCooking>(_onStartCooking);
    on<NextStep>(_onNextStep);
    on<PrevStep>(_onPrevStep);
    on<CancelCooking>(_onCancelCooking);
    on<CompleteCooking>(_onCompleteCooking);
  }

  Future<void> _onLoadRecipeDetail(LoadRecipeDetail event, Emitter<RecipeDetailState> emit) async {
    emit(state.copyWith(recipeId: event.recipeId));
    try {
      final recipes = await _recipeRepository.getRecipes();
      final recipe = recipes.firstWhere((r) => r.id == event.recipeId);
      final ingredients = await _recipeRepository.getRecipeIngredients(event.recipeId);
      final steps = await _recipeRepository.getRecipeSteps(event.recipeId);

      final user = _userRepository.getCurrentUser();
      bool isFav = false;
      if (user != null) {
        // Add to recently viewed
        await _recipeRepository.addRecentlyViewed(user.id, event.recipeId);
        
        final favorites = await _userRepository.getFavorites(user.id);
        isFav = favorites.any((f) => f.id == event.recipeId);
      }

      emit(state.copyWith(
        title: recipe.title,
        description: recipe.description,
        imageUrl: recipe.imageUrl,
        rating: recipe.rating.toString(),
        reviews: recipe.reviews.toString(),
        cookTime: recipe.cookTime,
        calories: recipe.calories,
        servings: recipe.servings,
        ingredients: ingredients,
        checkedIngredients: List.filled(ingredients.length, false),
        steps: steps,
        isFavorite: isFav,
      ));
    } catch (_) {}
  }

  void _onToggleIngredientCheck(ToggleIngredientCheck event, Emitter<RecipeDetailState> emit) {
    final updated = List<bool>.from(state.checkedIngredients);
    updated[event.index] = !updated[event.index];
    emit(state.copyWith(checkedIngredients: updated));
  }

  Future<void> _onToggleFavorite(ToggleFavorite event, Emitter<RecipeDetailState> emit) async {
    final user = _userRepository.getCurrentUser();
    if (user != null) {
      final nextFavState = !state.isFavorite;
      emit(state.copyWith(isFavorite: nextFavState));
      try {
        if (nextFavState) {
          await _userRepository.addFavorite(user.id, state.recipeId);
        } else {
          await _userRepository.removeFavorite(user.id, state.recipeId);
        }
      } catch (_) {
        // Rollback state on error
        emit(state.copyWith(isFavorite: !nextFavState));
      }
    }
  }

  void _onTabChanged(ChangeTab event, Emitter<RecipeDetailState> emit) {
    emit(state.copyWith(selectedTabIndex: event.index));
  }

  void _onStartCooking(StartCooking event, Emitter<RecipeDetailState> emit) {
    emit(state.copyWith(isCooking: true, currentCookingStep: 0));
  }

  void _onNextStep(NextStep event, Emitter<RecipeDetailState> emit) {
    if (state.currentCookingStep < state.steps.length - 1) {
      emit(state.copyWith(currentCookingStep: state.currentCookingStep + 1));
    }
  }

  void _onPrevStep(PrevStep event, Emitter<RecipeDetailState> emit) {
    if (state.currentCookingStep > 0) {
      emit(state.copyWith(currentCookingStep: state.currentCookingStep - 1));
    }
  }

  void _onCancelCooking(CancelCooking event, Emitter<RecipeDetailState> emit) {
    emit(state.copyWith(isCooking: false, currentCookingStep: 0));
  }

  Future<void> _onCompleteCooking(CompleteCooking event, Emitter<RecipeDetailState> emit) async {
    emit(state.copyWith(isCooking: false, currentCookingStep: 0));
    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        await _userRepository.markRecipeAsCooked(user.id, state.recipeId);
      } catch (_) {}
    }
  }
}
