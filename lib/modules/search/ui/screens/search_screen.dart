import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/cards/recipe_card.dart';
import '../../../../shared/widgets/chips/tag_chip.dart';
import '../../../../shared/widgets/search_bar/search_bar.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class SearchScreen extends StatefulWidget {
  final String? query;
  final String? category;

  const SearchScreen({this.query, this.category, super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RecipeSearchResult> _searchResults = [];
  bool _hasSearched = false;

  final List<String> _recentSearches = ['Salad', 'Healthy', 'Ramen', 'Quinoa'];

  final List<RecipeSearchResult> _mockRecipes = [
    RecipeSearchResult(
      id: 'r1',
      title: 'Mediterranean Quinoa Salad Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600',
      rating: '4.8',
      cookTime: '25 min',
      calories: '450 kcal',
    ),
    RecipeSearchResult(
      id: 'r2',
      title: 'Avocado Toast with Poached Egg',
      imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=600',
      rating: '4.7',
      cookTime: '15 min',
      calories: '320 kcal',
    ),
    RecipeSearchResult(
      id: 'r3',
      title: 'Spicy Creamy Tonkotsu Ramen',
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=600',
      rating: '4.9',
      cookTime: '35 min',
      calories: '650 kcal',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.query != null) {
      _searchController.text = widget.query!;
      _performSearch(widget.query!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _searchResults =
          _mockRecipes
              .where(
                (recipe) =>
                    recipe.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(Dimensions.space24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => const HomeRoute().go(context),
                    child: Icon(Icons.arrow_back_ios_new, color: context.grey.c900),
                  ),
                  const SizedBox(width: Dimensions.space16),
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchController,
                      hintText: context.l10n.searchPlaceholder,
                      autofocus: true,
                      onChanged: _performSearch,
                      onSubmitted: _performSearch,
                      onFilterPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            // Search filters tag bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.space24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TagChip(
                      label: 'Cuisine',
                      icon: Icons.keyboard_arrow_down,
                      backgroundColor: context.primary.c50,
                      textColor: context.primary.c600,
                    ),
                    const SizedBox(width: Dimensions.space8),
                    const TagChip(
                      label: 'Diet',
                      icon: Icons.keyboard_arrow_down,
                    ),
                    const SizedBox(width: Dimensions.space8),
                    const TagChip(
                      label: 'Time',
                      icon: Icons.keyboard_arrow_down,
                    ),
                    const SizedBox(width: Dimensions.space8),
                    const TagChip(
                      label: 'Calories',
                      icon: Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Dimensions.space24),
            // Body Area: Recent Searches OR Grid Results
            Expanded(
              child:
                  !_hasSearched
                      ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.space24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Searches',
                              style: context.typography.textMd.bold.copyWith(
                                color: context.grey.c900,
                              ),
                            ),
                            const SizedBox(height: Dimensions.space16),
                            Wrap(
                              spacing: Dimensions.space10,
                              runSpacing: Dimensions.space10,
                              children:
                                  _recentSearches.map((search) {
                                    return GestureDetector(
                                      onTap: () {
                                        _searchController.text = search;
                                        _performSearch(search);
                                      },
                                      child: TagChip(label: search),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      )
                      : _searchResults.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48.0,
                              color: context.grey.c300,
                            ),
                            const SizedBox(height: Dimensions.space12),
                            Text(
                              'No Recipes Found',
                              style: context.typography.textMd.bold.copyWith(
                                color: context.grey.c800,
                              ),
                            ),
                            const SizedBox(height: Dimensions.space4),
                            Text(
                              'Try searching for something else.',
                              style: context
                                  .typography
                                  .textSm
                                  .regular
                                  .copyWith(color: context.grey.c500),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.space24,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: Dimensions.space16,
                              mainAxisSpacing: Dimensions.space16,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final recipe = _searchResults[index];
                          return RecipeCard(
                            title: recipe.title,
                            imageUrl: recipe.imageUrl,
                            rating: recipe.rating,
                            cookTime: recipe.cookTime,
                            calories: recipe.calories,
                            onTap:
                                () => RecipeDetailRoute(recipeId: recipe.id)
                                    .push(context),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeSearchResult {
  final String id;
  final String title;
  final String imageUrl;
  final String rating;
  final String cookTime;
  final String calories;

  RecipeSearchResult({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.cookTime,
    required this.calories,
  });
}
