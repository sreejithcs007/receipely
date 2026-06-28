import 'package:flutter/material.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/app_bar/app_appbar.dart';
import '../../../../shared/widgets/cards/category_card.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const List<CategoryGridItem> _categories = [
    CategoryGridItem(label: 'Breakfast', icon: Icons.free_breakfast),
    CategoryGridItem(label: 'Lunch', icon: Icons.lunch_dining),
    CategoryGridItem(label: 'Dinner', icon: Icons.dinner_dining),
    CategoryGridItem(label: 'Desserts', icon: Icons.cake),
    CategoryGridItem(label: 'Drinks', icon: Icons.local_bar),
    CategoryGridItem(label: 'Healthy', icon: Icons.spa),
    CategoryGridItem(label: 'Vegan', icon: Icons.eco),
    CategoryGridItem(label: 'Italian', icon: Icons.restaurant),
    CategoryGridItem(label: 'Mexican', icon: Icons.local_pizza),
    CategoryGridItem(label: 'Asian', icon: Icons.rice_bowl),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      appBar: const AppAppBar(title: 'Categories', showBackButton: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(Dimensions.space24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: Dimensions.space16,
          mainAxisSpacing: Dimensions.space24,
          childAspectRatio: 0.85,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return CategoryCard(
            label: category.label,
            icon: category.icon,
            isActive: false,
            onTap: () {},
          );
        },
      ),
    );
  }
}

class CategoryGridItem {
  final String label;
  final IconData icon;
  const CategoryGridItem({required this.label, required this.icon});
}
