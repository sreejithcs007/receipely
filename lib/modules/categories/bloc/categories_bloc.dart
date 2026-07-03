import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/data/repositories/recipe_repository.dart';
import 'categories_event.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final RecipeRepository _recipeRepository;

  CategoriesBloc(this._recipeRepository) : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoriesState> emit) async {
    emit(CategoriesLoading());
    try {
      final categories = await _recipeRepository.getCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}
