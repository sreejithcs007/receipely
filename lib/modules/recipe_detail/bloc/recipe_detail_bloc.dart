import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import 'recipe_detail_event.dart';
import 'recipe_detail_state.dart';

class RecipeDetailBloc extends Bloc<RecipeDetailEvent, RecipeDetailState> {
  RecipeDetailBloc()
      : super(RecipeDetailState(
          recipeId: 'truffle_pasta',
          title: 'Truffle Mushroom Pasta',
          description: 'A creamy and indulgent pasta dish with earthy mushrooms, aromatic truffle oil, and parmesan.',
          imageUrl: AppImages.heroBanner,
          rating: '4.9',
          reviews: '2.3k',
          cookTime: '30 min',
          calories: '520 cal',
          servings: '4 servings',
          ingredients: const [
            '12 oz fettuccine pasta',
            '2 tbsp olive oil',
            '3 cloves garlic, minced',
            '8 oz cremini mushrooms, sliced',
            '1/2 cup heavy cream',
            '1/4 cup grated parmesan cheese',
            '1 tbsp truffle oil',
            'Salt and black pepper, to taste',
          ],
          checkedIngredients: List.filled(8, false),
          steps: const [
            'Boil pasta in salted water according to package directions until al dente.',
            'Heat olive oil in a large skillet over medium-high heat. Add minced garlic and sauté until fragrant.',
            'Add cremini mushrooms and cook until browned, about 5-7 minutes. Season with salt and pepper.',
            'Reduce heat to low, stir in heavy cream and grated parmesan cheese. Simmer gently for 2 minutes.',
            'Drain pasta and toss it in the skillet with the creamy mushroom sauce. Drizzle with truffle oil before serving.',
          ],
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
  }

  void _onLoadRecipeDetail(LoadRecipeDetail event, Emitter<RecipeDetailState> emit) {
    emit(state.copyWith(recipeId: event.recipeId));
  }

  void _onToggleIngredientCheck(ToggleIngredientCheck event, Emitter<RecipeDetailState> emit) {
    final updated = List<bool>.from(state.checkedIngredients);
    updated[event.index] = !updated[event.index];
    emit(state.copyWith(checkedIngredients: updated));
  }

  void _onToggleFavorite(ToggleFavorite event, Emitter<RecipeDetailState> emit) {
    emit(state.copyWith(isFavorite: !state.isFavorite));
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
}
