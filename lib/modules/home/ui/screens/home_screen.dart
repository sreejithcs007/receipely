import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/cards/category_card.dart';
import '../../../../shared/widgets/cards/recipe_card.dart';
import '../../../../shared/widgets/avatar/profile_avatar.dart';
import '../../../../shared/widgets/search_bar/search_bar.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeCategoryIndex = 0;

  final List<CategoryItem> _categories = [
    CategoryItem(label: 'Breakfast', icon: Icons.free_breakfast),
    CategoryItem(label: 'Lunch', icon: Icons.lunch_dining),
    CategoryItem(label: 'Dinner', icon: Icons.dinner_dining),
    CategoryItem(label: 'Dessert', icon: Icons.cake),
    CategoryItem(label: 'Beverage', icon: Icons.local_bar),
  ];



  final List<RecipeItem> _trendingRecipes = [
    RecipeItem(
      id: 'r1',
      title: 'Spicy Creamy Tonkotsu Ramen',
      imageUrl: AppImages.recipeRamen,
      rating: '4.9',
      cookTime: '35 min',
      calories: '650 kcal',
    ),
    RecipeItem(
      id: 'r2',
      title: 'Avocado Toast with Poached Egg',
      imageUrl: AppImages.recipeAvocadoToast,
      rating: '4.7',
      cookTime: '15 min',
      calories: '320 kcal',
    ),
    RecipeItem(
      id: 'r3',
      title: 'Grilled Salmon with Asparagus',
      imageUrl: AppImages.recipeSalmon,
      rating: '4.8',
      cookTime: '25 min',
      calories: '450 kcal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space24,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: context.typography.textMd.medium.copyWith(
                            color: context.grey.c500,
                          ),
                        ),
                        Text(
                          'Chef John 👋',
                          style: context.typography.displayXs.bold.copyWith(
                            color: context.grey.c900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ProfileAvatar(
                      name: 'Chef John',
                      imageUrl: AppImages.chefAvatar,
                      radius: 26.0,
                      onTap: () => const ProfileRoute().go(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.space24),
              // Search Bar Trigger
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space24,
                ),
                child: GestureDetector(
                  onTap: () => const SearchRoute().go(context),
                  child: AbsorbPointer(
                    child: AppSearchBar(
                      hintText: context.l10n.searchPlaceholder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space32),
              // Categories Title & List
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space24,
                ),
                child: Text(
                  'Popular Categories',
                  style: context.typography.textLg.bold.copyWith(
                    color: context.grey.c900,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space16),
              SizedBox(
                height: 100.0,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space24,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder:
                      (context, index) =>
                          const SizedBox(width: Dimensions.space20),
                  itemBuilder: (context, index) {
                    final item = _categories[index];
                    return CategoryCard(
                      label: item.label,
                      icon: item.icon,
                      isActive: _activeCategoryIndex == index,
                      onTap: () {
                        setState(() {
                          _activeCategoryIndex = index;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: Dimensions.space24),
              // Featured Hero Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space24,
                ),
                child: Text(
                  'Featured Recipe',
                  style: context.typography.textLg.bold.copyWith(
                    color: context.grey.c900,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space24,
                ),
                child: GestureDetector(
                  onTap:
                      () => const RecipeDetailRoute(recipeId: 'featured_1')
                          .push(context),
                  child: Container(
                    height: 180.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusLg),
                      image: const DecorationImage(
                        image: AssetImage(AppImages.heroBanner),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusLg,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(Dimensions.space20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.space8,
                              vertical: Dimensions.space4,
                            ),
                            decoration: BoxDecoration(
                              color: context.primary.c500,
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusXs,
                              ),
                            ),
                            child: Text(
                              'CHEF PICK',
                              style: context.typography.textXs.bold.copyWith(
                                color: context.white.c50,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.space8),
                          Text(
                            'Mediterranean Quinoa Salad Bowl',
                            style: context.typography.textLg.bold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: Dimensions.space4),
                          Text(
                            'Fresh cucumber, olives, feta cheese, and garlic dressing.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.typography.textXs.regular.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space32),
              // Trending Recipes Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space24,
                ),
                child: Row(
                  children: [
                    Text(
                      'Trending Recipes',
                      style: context.typography.textLg.bold.copyWith(
                        color: context.grey.c900,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => const CategoriesRoute().push(context),
                      child: Text(
                        'See All',
                        style: context.typography.textSm.semibold.copyWith(
                          color: context.primary.c500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.space16),
              SizedBox(
                height: 240.0,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space24,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _trendingRecipes.length,
                  separatorBuilder:
                      (context, index) =>
                          const SizedBox(width: Dimensions.space16),
                  itemBuilder: (context, index) {
                    final item = _trendingRecipes[index];
                    return RecipeCard(
                      title: item.title,
                      imageUrl: item.imageUrl,
                      rating: item.rating,
                      cookTime: item.cookTime,
                      calories: item.calories,
                      isFavorite: index == 0,
                      onTap:
                          () => RecipeDetailRoute(recipeId: item.id).push(
                            context,
                          ),
                      onFavoriteToggled: () {},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String label;
  final IconData icon;
  CategoryItem({required this.label, required this.icon});
}

class RecipeItem {
  final String id;
  final String title;
  final String imageUrl;
  final String rating;
  final String cookTime;
  final String calories;

  RecipeItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.cookTime,
    required this.calories,
  });
}
