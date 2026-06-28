import 'package:flutter/material.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/app_bar/app_appbar.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  int _activeDayIndex = 0;

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      appBar: const AppAppBar(title: 'Meal Planner', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar weekday row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_weekDays.length, (index) {
                final bool isActive = _activeDayIndex == index;
                final Color background =
                    isActive ? context.primary.c500 : context.grey.c50;
                final Color textColor =
                    isActive ? context.white.c50 : context.grey.c600;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 44.0,
                    height: 52.0,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekDays[index],
                          style: context.typography.textXs.regular.copyWith(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${index + 20}', // Mock day numbers
                          style: context.typography.textSm.bold.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: Dimensions.space32),
            // Target Nutrition Bar Cards
            Text(
              'Nutrition Target',
              style: context.typography.textMd.bold.copyWith(
                color: context.grey.c900,
              ),
            ),
            const SizedBox(height: Dimensions.space16),
            Container(
              padding: const EdgeInsets.all(Dimensions.space16),
              decoration: BoxDecoration(
                color: context.grey.c50,
                borderRadius: BorderRadius.circular(Dimensions.radiusMd),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1,850 / 2,300 kcal consumed',
                        style: context.typography.textSm.medium.copyWith(
                          color: context.grey.c700,
                        ),
                      ),
                      Text(
                        '80%',
                        style: context.typography.textSm.bold.copyWith(
                          color: context.primary.c500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.space8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusFull),
                    child: LinearProgressIndicator(
                      value: 0.8,
                      minHeight: 8.0,
                      backgroundColor: context.grey.c200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.primary.c500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space32),
            // Meal Slots
            Text(
              'Daily Menu',
              style: context.typography.textMd.bold.copyWith(
                color: context.grey.c900,
              ),
            ),
            const SizedBox(height: Dimensions.space16),
            _buildMealSlotCard(
              slotName: 'Breakfast',
              recipeTitle: 'Scrambled Eggs with Avocado',
              cookTime: '10 min',
              calories: '280 kcal',
              imageUrl: AppImages.recipeAvocadoToast,
            ),
            const SizedBox(height: Dimensions.space16),
            _buildMealSlotCard(
              slotName: 'Lunch',
              recipeTitle: 'Mediterranean Quinoa Salad Bowl',
              cookTime: '25 min',
              calories: '450 kcal',
              imageUrl: AppImages.heroBanner,
            ),
            const SizedBox(height: Dimensions.space16),
            _buildMealSlotCard(
              slotName: 'Dinner',
              recipeTitle: 'Honey Mustard Salmon Roast',
              cookTime: '30 min',
              calories: '510 kcal',
              imageUrl: AppImages.recipeSalmon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlotCard({
    required String slotName,
    required String recipeTitle,
    required String cookTime,
    required String calories,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: context.white.c50,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: context.grey.c200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            child: Image.asset(
              imageUrl,
              width: 60.0,
              height: 60.0,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: Dimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slotName.toUpperCase(),
                  style: context.typography.textXs.bold.copyWith(
                    color: context.primary.c500,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  recipeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.textSm.semibold.copyWith(
                    color: context.grey.c900,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12.0, color: context.grey.c500),
                    const SizedBox(width: 2.0),
                    Text(
                      cookTime,
                      style: context.typography.textXs.regular.copyWith(
                        color: context.grey.c500,
                      ),
                    ),
                    const SizedBox(width: Dimensions.space12),
                    Icon(
                      Icons.local_fire_department,
                      size: 12.0,
                      color: context.grey.c500,
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      calories,
                      style: context.typography.textXs.regular.copyWith(
                        color: context.grey.c500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: context.grey.c400),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
