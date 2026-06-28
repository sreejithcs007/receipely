import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/app_bar/app_appbar.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/chips/ingredient_chip.dart';
import '../../../../shared/widgets/chips/tag_chip.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class AiGeneratorScreen extends StatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  State<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends State<AiGeneratorScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = ['Quinoa', 'Avocado', 'Tomato'];
  bool _isGenerating = false;
  bool _hasGenerated = false;

  final List<String> _quickSuggestions = [
    'Chicken',
    'Cheese',
    'Rice',
    'Garlic',
    'Egg',
  ];

  void _addIngredient(String ingredient) {
    if (ingredient.trim().isEmpty) return;
    if (!_ingredients.contains(ingredient.trim())) {
      setState(() {
        _ingredients.add(ingredient.trim());
      });
    }
    _ingredientController.clear();
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  void _generateRecipe() {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasGenerated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      appBar: const AppAppBar(title: 'AI Generator', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What ingredients do you have?',
              style: context.typography.textLg.bold.copyWith(
                color: context.grey.c900,
              ),
            ),
            const SizedBox(height: Dimensions.space8),
            Text(
              'Add ingredients from your pantry to generate recipes.',
              style: context.typography.textSm.regular.copyWith(
                color: context.grey.c500,
              ),
            ),
            const SizedBox(height: Dimensions.space24),
            // Ingredient input field row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    style: context.typography.textMd.regular.copyWith(
                      color: context.grey.c900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add ingredient...',
                      hintStyle: TextStyle(color: context.grey.c400),
                      filled: true,
                      fillColor: context.grey.c50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                        borderSide: BorderSide(color: context.grey.c200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                        borderSide: BorderSide(color: context.grey.c200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                        borderSide: BorderSide(color: context.primary.c500),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.space16,
                        vertical: Dimensions.space12,
                      ),
                    ),
                    onSubmitted: _addIngredient,
                  ),
                ),
                const SizedBox(width: Dimensions.space12),
                PrimaryButton(
                  label: 'Add',
                  onPressed: () => _addIngredient(_ingredientController.text),
                  width: 80.0,
                  height: 48.0,
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space20),
            // Ingredients list tags wrap
            if (_ingredients.isNotEmpty) ...[
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    _ingredients.map((ingredient) {
                      return IngredientChip(
                        label: ingredient,
                        onDeleted: () => _removeIngredient(ingredient),
                      );
                    }).toList(),
              ),
              const SizedBox(height: Dimensions.space24),
            ],
            // Quick suggestions
            Text(
              'Quick Add Suggestions',
              style: context.typography.textSm.semibold.copyWith(
                color: context.grey.c700,
              ),
            ),
            const SizedBox(height: Dimensions.space12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _quickSuggestions.map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () => _addIngredient(suggestion),
                          child: TagChip(label: '+ $suggestion'),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: Dimensions.space40),
            PrimaryButton(
              label: 'Generate Recipe',
              icon: Icons.auto_awesome,
              isLoading: _isGenerating,
              onPressed: _generateRecipe,
            ),
            const SizedBox(height: Dimensions.space32),
            // AI Suggests Result Panel
            if (_hasGenerated && !_isGenerating) ...[
              Text(
                'AI Recommendation',
                style: context.typography.textLg.bold.copyWith(
                  color: context.grey.c900,
                ),
              ),
              const SizedBox(height: Dimensions.space16),
              Container(
                padding: const EdgeInsets.all(Dimensions.space16),
                decoration: BoxDecoration(
                  color: context.white.c50,
                  borderRadius: BorderRadius.circular(Dimensions.radiusLg),
                  border: Border.all(color: context.primary.c100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: context.primary.c500.withValues(alpha: 0.04),
                      blurRadius: 16.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                      child: Image.asset(
                        AppImages.heroBanner,
                        height: 140.0,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.space8,
                            vertical: Dimensions.space4,
                          ),
                          decoration: BoxDecoration(
                            color: context.secondary.c50,
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusXs,
                            ),
                          ),
                          child: Text(
                            '95% INGREDIENT MATCH',
                            style: context.typography.textXs.bold.copyWith(
                              color: context.secondary.c600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 16.0),
                        const SizedBox(width: 4.0),
                        Text(
                          '4.8',
                          style: context.typography.textXs.bold.copyWith(
                            color: context.grey.c900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.space12),
                    Text(
                      'Mediterranean Quinoa Salad Bowl',
                      style: context.typography.textMd.bold.copyWith(
                        color: context.grey.c900,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space4),
                    Text(
                      'Contains Quinoa, Avocado, Tomatoes and olive oil dressing.',
                      style: context.typography.textXs.regular.copyWith(
                        color: context.grey.c500,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space16),
                    PrimaryButton(
                      label: 'View Recipe Detail',
                      height: 44.0,
                      onPressed:
                          () => const RecipeDetailRoute(recipeId: 'ai_gen_1')
                              .push(context),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
