import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/app_bar/app_appbar.dart';
import '../../../../shared/widgets/cards/category_card.dart';
import '../../../../shared/utils/extension/context_extension.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../bloc/categories_bloc.dart';
import '../../bloc/categories_event.dart';
import '../../bloc/categories_state.dart';

IconData _getCategoryIcon(String name) {
  switch (name.toLowerCase()) {
    case 'breakfast':
      return Icons.free_breakfast;
    case 'lunch':
      return Icons.lunch_dining;
    case 'dinner':
      return Icons.dinner_dining;
    case 'desserts':
    case 'dessert':
      return Icons.cake;
    case 'drinks':
    case 'beverages':
      return Icons.local_bar;
    case 'healthy':
      return Icons.spa;
    case 'vegan':
      return Icons.eco;
    case 'italian':
      return Icons.restaurant;
    case 'mexican':
      return Icons.local_pizza;
    case 'asian':
    case 'japanese':
      return Icons.rice_bowl;
    default:
      return Icons.restaurant;
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoriesBloc>(
      create: (context) => CategoriesBloc(getIt<RecipeRepository>())..add(LoadCategories()),
      child: Scaffold(
        backgroundColor: context.white.c50,
        appBar: const AppAppBar(title: 'Categories', showBackButton: true),
        body: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF47B20),
                ),
              );
            }
            if (state is CategoriesError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            }
            if (state is CategoriesLoaded) {
              final categories = state.categories;
              return GridView.builder(
                padding: const EdgeInsets.all(Dimensions.space24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: Dimensions.space16,
                  mainAxisSpacing: Dimensions.space24,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    label: category.name,
                    icon: _getCategoryIcon(category.name),
                    isActive: false,
                    onTap: () {
                      // Navigate to search screen or recipe list with this category filter
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
