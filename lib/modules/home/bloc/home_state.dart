import 'package:equatable/equatable.dart';
import '../../../shared/data/models/category_model.dart';
import '../../../shared/data/models/recipe_model.dart';
import '../../../shared/data/models/user_profile_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<CategoryModel> categories;
  final List<RecipeModel> featuredRecipes;
  final List<RecipeModel> trendingRecipes;
  final UserProfileModel? userProfile;

  const HomeLoaded({
    required this.categories,
    required this.featuredRecipes,
    required this.trendingRecipes,
    this.userProfile,
  });

  @override
  List<Object?> get props => [categories, featuredRecipes, trendingRecipes, userProfile];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
