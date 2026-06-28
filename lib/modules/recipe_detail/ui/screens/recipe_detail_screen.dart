import 'package:flutter/material.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/cards/nutrition_badge.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({required this.recipeId, super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _servingsCount = 2;
  bool _isFavorite = false;

  final List<String> _ingredients = [
    '200g Fresh Quinoa grains',
    '1 Organic Avocado, sliced',
    '100g Cherry Tomatoes, halved',
    '50g Greek Feta Cheese',
    '2 tbsp Olive Oil dressing',
    '1 Clove Garlic, minced',
  ];

  final List<String> _steps = [
    'Rinse quinoa thoroughly, cook in boiling salted water for 15 minutes, then drain and set aside to cool.',
    'Halve the cherry tomatoes, slice the avocado, and crumble the feta cheese into a mixing bowl.',
    'Whisk olive oil, minced garlic, lemon juice, salt, and pepper in a small bowl to make the dressing.',
    'Toss cooked quinoa with the chopped vegetables, feta, and dressing in a large bowl.',
    'Garnish with fresh parsley and serve immediately or store chilled.',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      body: Column(
        children: [
          // Hero cover image section
          Stack(
            children: [
              Container(
                height: 280.0,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              // Top Action Buttons
              Positioned(
                top: MediaQuery.of(context).padding.top + 12.0,
                left: Dimensions.space16,
                right: Dimensions.space16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(Dimensions.space10),
                        decoration: BoxDecoration(
                          color: context.white.c50.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18.0,
                          color: context.grey.c900,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(Dimensions.space10),
                        decoration: BoxDecoration(
                          color: context.white.c50.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          size: 18.0,
                          color:
                              _isFavorite
                                  ? context.primary.c500
                                  : context.grey.c900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Scrollable details section
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              decoration: BoxDecoration(
                color: context.white.c50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusXl),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.space24,
                        vertical: Dimensions.space20,
                      ),
                      children: [
                        // Recipe title
                        Text(
                          'Mediterranean Quinoa Salad Bowl',
                          style: context.typography.textXl.bold.copyWith(
                            color: context.grey.c900,
                          ),
                        ),
                        const SizedBox(height: Dimensions.space8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16.0,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              '4.8',
                              style: context.typography.textSm.bold.copyWith(
                                color: context.grey.c900,
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              '(2.3k reviews)',
                              style: context.typography.textXs.regular.copyWith(
                                color: context.grey.c400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.space20),
                        // Servings controller row
                        Row(
                          children: [
                            Text(
                              'Servings',
                              style: context.typography.textMd.semibold
                                  .copyWith(color: context.grey.c900),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: context.grey.c50,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusFull,
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18.0),
                                    onPressed: () {
                                      if (_servingsCount > 1) {
                                        setState(() {
                                          _servingsCount--;
                                        });
                                      }
                                    },
                                  ),
                                  Text(
                                    '$_servingsCount',
                                    style: context
                                        .typography
                                        .textMd
                                        .semibold
                                        .copyWith(color: context.grey.c900),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18.0),
                                    onPressed: () {
                                      setState(() {
                                        _servingsCount++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.space24),
                        // Nutrition Row
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NutritionBadge(label: 'Protein', value: '18g'),
                            NutritionBadge(label: 'Carbs', value: '54g'),
                            NutritionBadge(label: 'Fat', value: '12g'),
                            NutritionBadge(label: 'Calories', value: '450 kcal'),
                          ],
                        ),
                        const SizedBox(height: Dimensions.space24),
                        // Tab selectors
                        TabBar(
                          controller: _tabController,
                          labelColor: context.primary.c500,
                          unselectedLabelColor: context.grey.c400,
                          indicatorColor: context.primary.c500,
                          labelStyle: context.typography.textMd.semibold,
                          tabs: const [
                            Tab(text: 'Ingredients'),
                            Tab(text: 'Steps'),
                          ],
                        ),
                        const SizedBox(height: Dimensions.space16),
                        // Tab contents
                        SizedBox(
                          height: 320.0,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Ingredients Checkbox Tab
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _ingredients.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(height: 8.0),
                                itemBuilder: (context, index) {
                                  return Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: context.primary.c500,
                                        size: 20.0,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.space12,
                                      ),
                                      Expanded(
                                        child: Text(
                                          _ingredients[index],
                                          style: context
                                              .typography
                                              .textSm
                                              .medium
                                              .copyWith(
                                                color: context.grey.c800,
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              // Steps List Tab
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _steps.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(height: 12.0),
                                itemBuilder: (context, index) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24.0,
                                        height: 24.0,
                                        decoration: BoxDecoration(
                                          color: context.primary.c50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: context
                                                .typography
                                                .textXs
                                                .bold
                                                .copyWith(
                                                  color: context.primary.c500,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: Dimensions.space12,
                                      ),
                                      Expanded(
                                        child: Text(
                                          _steps[index],
                                          style: context
                                              .typography
                                              .textSm
                                              .regular
                                              .copyWith(
                                                color: context.grey.c700,
                                                height: 1.4,
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom Sticky CTA Action Panel
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space24),
                    decoration: BoxDecoration(
                      color: context.white.c50,
                      border: Border(
                        top: BorderSide(color: context.grey.c100),
                      ),
                    ),
                    child: PrimaryButton(
                      label: 'Start Cooking',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
