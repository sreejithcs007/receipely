import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/data/repositories/recipe_repository.dart';
import '../../../shared/data/repositories/user_repository.dart';
import '../../../shared/data/models/user_profile_model.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;

  HomeBloc(this._recipeRepository, this._userRepository) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<ToggleFavoriteRecipe>(_onToggleFavoriteRecipe);
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final categories = await _recipeRepository.getCategories();
      final featured = await _recipeRepository.getFeaturedRecipes();
      final trending = await _recipeRepository.getTrendingRecipes();
      
      final user = _userRepository.getCurrentUser();
      UserProfileModel? profile;
      if (user != null) {
        try {
          profile = await _userRepository.getUserProfile(user.id);
        } catch (_) {
          try {
            await _userRepository.createUserProfileIfMissing(
              user.id,
              user.email ?? 'user@recipely.app',
              user.userMetadata?['name'] as String? ?? user.email?.split('@').first ?? 'Sarah',
            );
            profile = await _userRepository.getUserProfile(user.id);
          } catch (_) {}
        }
      }

      List<String> favoriteRecipeIds = [];
      if (user != null) {
        try {
          final favorites = await _userRepository.getFavorites(user.id);
          favoriteRecipeIds = favorites.map((r) => r.id).toList();
        } catch (_) {}
      }

      emit(HomeLoaded(
        categories: categories,
        featuredRecipes: featured,
        trendingRecipes: trending,
        favoriteRecipeIds: favoriteRecipeIds,
        userProfile: profile,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onToggleFavoriteRecipe(ToggleFavoriteRecipe event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final isFavorited = currentState.favoriteRecipeIds.contains(event.recipeId);
      final updatedFavorites = List<String>.from(currentState.favoriteRecipeIds);

      if (isFavorited) {
        updatedFavorites.remove(event.recipeId);
      } else {
        updatedFavorites.add(event.recipeId);
      }

      // Optimistic UI state update (color changes instantly)
      emit(currentState.copyWith(favoriteRecipeIds: updatedFavorites));

      final user = _userRepository.getCurrentUser();
      if (user != null) {
        try {
          if (isFavorited) {
            await _userRepository.removeFavorite(user.id, event.recipeId);
          } else {
            await _userRepository.addFavorite(user.id, event.recipeId);
          }
        } catch (_) {
          // Revert on error if desired
        }
      }
    }
  }
}
