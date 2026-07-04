import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/data/repositories/recipe_repository.dart';
import '../../../shared/data/repositories/user_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;

  HomeBloc(this._recipeRepository, this._userRepository)
    : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      final categories = await _recipeRepository.getCategories();
      final featured = await _recipeRepository.getFeaturedRecipes();
      print('hello == i am at line 20 of homebloc');
      final trending = await _recipeRepository.getTrendingRecipes();

      final user = _userRepository.getCurrentUser();
      final profile = (user != null)
          ? await _userRepository.getUserProfile(user.id)
          : null;

      emit(
        HomeLoaded(
          categories: categories,
          featuredRecipes: featured,
          trendingRecipes: trending,
          userProfile: profile,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
