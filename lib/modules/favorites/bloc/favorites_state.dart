import 'package:equatable/equatable.dart';

class FavoriteRecipeItem extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String cookTime;
  final String difficulty;
  final DateTime favoritedAt;

  const FavoriteRecipeItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.cookTime,
    required this.difficulty,
    required this.favoritedAt,
  });

  @override
  List<Object?> get props => [id, title, imageUrl, cookTime, difficulty, favoritedAt];
}

enum FavoritesSortType {
  latestToOldest,
  oldestToLatest,
  alphabeticalAZ,
  alphabeticalZA,
}

class FavoritesState extends Equatable {
  final List<FavoriteRecipeItem> favorites;
  final FavoritesSortType sortType;
  final bool isLoading;

  const FavoritesState({
    required this.favorites,
    required this.sortType,
    required this.isLoading,
  });

  FavoritesState copyWith({
    List<FavoriteRecipeItem>? favorites,
    FavoritesSortType? sortType,
    bool? isLoading,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      sortType: sortType ?? this.sortType,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [favorites, sortType, isLoading];
}
