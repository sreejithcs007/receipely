import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/app_bar/app_appbar.dart';
import '../../../../shared/widgets/cards/recipe_card.dart';
import '../../../../shared/widgets/layout/empty_state_widget.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<FavoriteRecipeItem> _favorites = [
    FavoriteRecipeItem(
      id: 'r1',
      title: 'Mediterranean Quinoa Salad Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600',
      rating: '4.8',
      cookTime: '25 min',
      calories: '450 kcal',
    ),
    FavoriteRecipeItem(
      id: 'r3',
      title: 'Grilled Salmon with Asparagus',
      imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=600',
      rating: '4.8',
      cookTime: '25 min',
      calories: '450 kcal',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      appBar: AppAppBar(
        title: 'Favorites',
        showBackButton: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primary.c500,
          unselectedLabelColor: context.grey.c400,
          indicatorColor: context.primary.c500,
          labelStyle: context.typography.textMd.semibold,
          tabs: const [
            Tab(text: 'All Recipes'),
            Tab(text: 'Collections'),
            Tab(text: 'Chefs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Recipes Tab Result
          _favorites.isEmpty
              ? const EmptyStateWidget(
                icon: Icons.bookmark_outline,
                title: 'No Favorites Yet',
                description: 'Bookmark recipes to save them here.',
              )
              : GridView.builder(
                padding: const EdgeInsets.all(Dimensions.space24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: Dimensions.space16,
                  mainAxisSpacing: Dimensions.space16,
                  childAspectRatio: 0.72,
                ),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final recipe = _favorites[index];
                  return RecipeCard(
                    title: recipe.title,
                    imageUrl: recipe.imageUrl,
                    rating: recipe.rating,
                    cookTime: recipe.cookTime,
                    calories: recipe.calories,
                    isFavorite: true,
                    onTap:
                        () => RecipeDetailRoute(recipeId: recipe.id).push(
                          context,
                        ),
                  );
                },
              ),
          // Collections Tab Placeholder
          const EmptyStateWidget(
            icon: Icons.folder_open_outlined,
            title: 'No Collections Created',
            description: 'Organize your recipes into custom folders.',
          ),
          // Chefs Tab Placeholder
          const EmptyStateWidget(
            icon: Icons.people_outline,
            title: 'No Chefs Followed',
            description: 'Follow home chefs to see their daily uploads.',
          ),
        ],
      ),
    );
  }
}

class FavoriteRecipeItem {
  final String id;
  final String title;
  final String imageUrl;
  final String rating;
  final String cookTime;
  final String calories;

  FavoriteRecipeItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.cookTime,
    required this.calories,
  });
}
