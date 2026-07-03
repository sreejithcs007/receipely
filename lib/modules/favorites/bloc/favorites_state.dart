import 'package:equatable/equatable.dart';

class FavoriteRecipeItem extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String cookTime;
  final String difficulty;

  const FavoriteRecipeItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.cookTime,
    required this.difficulty,
  });

  @override
  List<Object?> get props => [id, title, imageUrl, cookTime, difficulty];
}

class FavoriteCollectionItem extends Equatable {
  final String id;
  final String name;
  final int recipeCount;
  final int badgeHexColor; // Background color for the folder badge

  const FavoriteCollectionItem({
    required this.id,
    required this.name,
    required this.recipeCount,
    required this.badgeHexColor,
  });

  @override
  List<Object?> get props => [id, name, recipeCount, badgeHexColor];
}

class FavoritesState extends Equatable {
  final int selectedTabIndex; // 0 = All, 1 = Collections
  final List<FavoriteRecipeItem> favorites;
  final List<FavoriteCollectionItem> collections;
  final bool isLoading;

  const FavoritesState({
    required this.selectedTabIndex,
    required this.favorites,
    required this.collections,
    required this.isLoading,
  });

  FavoritesState copyWith({
    int? selectedTabIndex,
    List<FavoriteRecipeItem>? favorites,
    List<FavoriteCollectionItem>? collections,
    bool? isLoading,
  }) {
    return FavoritesState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      favorites: favorites ?? this.favorites,
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [selectedTabIndex, favorites, collections, isLoading];
}
