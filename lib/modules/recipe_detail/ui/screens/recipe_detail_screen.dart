import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../bloc/recipe_detail_bloc.dart';
import '../../bloc/recipe_detail_event.dart';
import '../../bloc/recipe_detail_state.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({required this.recipeId, super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecipeDetailBloc(
        getIt<RecipeRepository>(),
        getIt<UserRepository>(),
      )..add(LoadRecipeDetail(widget.recipeId)),
      child: BlocBuilder<RecipeDetailBloc, RecipeDetailState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2), // Canvas
            body: Stack(
              children: [
                // ── Main Detail Scroll View ──────────────────────────────────
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Image with Back/Fav buttons
                            _buildHeaderImage(context, state),

                            // Recipe Info
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    state.title,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F1E1C),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Description
                                  Text(
                                    state.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF8C8A87),
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Stats Row
                                  _buildStatsRow(state),
                                  const SizedBox(height: 28),

                                  // Custom Tabs (Ingredients / Steps)
                                  _buildCustomTabBar(context, state),
                                  const SizedBox(height: 20),

                                  // Tab Content View
                                  state.selectedTabIndex == 0
                                      ? _buildIngredientsTab(context, state)
                                      : _buildStepsTab(state),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sticky Bottom CTA Action Bar
                    _buildBottomBar(context),
                  ],
                ),

                // ── Full-screen Cooking Guide Overlay ─────────────────────────
                if (state.isCooking)
                  _buildCookingOverlay(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context, RecipeDetailState state) {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        children: [
          // Curved Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: state.imageUrl.startsWith('http')
                  ? Image.network(
                      state.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppImages.recipeRamen,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      state.imageUrl.isNotEmpty ? state.imageUrl : AppImages.recipeRamen,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          // Dark Top Gradient Overlay for back buttons contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Circle Floating Actions
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF1F1E1C),
                      size: 24,
                    ),
                  ),
                ),
                // Right buttons (Bookmark & Share)
                Row(
                  children: [
                    // Bookmark
                    GestureDetector(
                      onTap: () {
                        context.read<RecipeDetailBloc>().add(ToggleFavorite());
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          state.isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: state.isFavorite ? const Color(0xFFF47B20) : const Color(0xFF1F1E1C),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Share
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: Color(0xFF1F1E1C),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(RecipeDetailState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEBE4), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rating
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF47B20), size: 18),
              const SizedBox(width: 4),
              Text(
                state.rating,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
              const SizedBox(width: 2),
              Text(
                '(${state.reviews})',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8C8A87)),
              ),
            ],
          ),
          const SizedBox(height: 16, child: VerticalDivider(color: Color(0xFFEFEBE4), width: 1)),

          // Cook Time
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFFF47B20), size: 16),
              const SizedBox(width: 4),
              Text(
                state.cookTime,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
            ],
          ),
          const SizedBox(height: 16, child: VerticalDivider(color: Color(0xFFEFEBE4), width: 1)),

          // Calories
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF47B20), size: 17),
              const SizedBox(width: 4),
              Text(
                state.calories,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
            ],
          ),
          const SizedBox(height: 16, child: VerticalDivider(color: Color(0xFFEFEBE4), width: 1)),

          // Servings
          Row(
            children: [
              const Icon(Icons.people_outline_rounded, color: Color(0xFFF47B20), size: 17),
              const SizedBox(width: 4),
              Text(
                state.servings,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1F1E1C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context, RecipeDetailState state) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Ingredients Tab
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.read<RecipeDetailBloc>().add(const ChangeTab(0));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: state.selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: state.selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Ingredients',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: state.selectedTabIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                      color: state.selectedTabIndex == 0 ? const Color(0xFF1F1E1C) : const Color(0xFF8C8A87),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Steps Tab
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.read<RecipeDetailBloc>().add(const ChangeTab(1));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: state.selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: state.selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Steps',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: state.selectedTabIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                      color: state.selectedTabIndex == 1 ? const Color(0xFF1F1E1C) : const Color(0xFF8C8A87),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(BuildContext context, RecipeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ingredients',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            Text(
              '${state.ingredients.length} items',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF47B20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.ingredients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ingredient = state.ingredients[index];
            final isChecked = state.checkedIngredients[index];

            return GestureDetector(
              onTap: () {
                context.read<RecipeDetailBloc>().add(ToggleIngredientCheck(index));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? const Color(0xFFF47B20).withValues(alpha: 0.3) : const Color(0xFFEFEBE4),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Rounded Custom Checkbox
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(6),
                        color: isChecked ? const Color(0xFFF47B20) : Colors.transparent,
                        border: Border.all(
                          color: isChecked ? const Color(0xFFF47B20) : const Color(0xFFB5B3B0),
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Ingredient Title (strike-through when checked)
                    Expanded(
                      child: Text(
                        ingredient,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isChecked ? const Color(0xFFB5B3B0) : const Color(0xFF1F1E1C),
                          decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepsTab(RecipeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cooking Instructions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1E1C),
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final step = state.steps[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF2D9),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF47B20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Instruction Text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      step,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1F1E1C),
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47B20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              context.read<RecipeDetailBloc>().add(StartCooking());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Start Cooking',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCookingOverlay(BuildContext context, RecipeDetailState state) {
    final stepIndex = state.currentCookingStep;
    final totalSteps = state.steps.length;
    final progress = (stepIndex + 1) / totalSteps;
    final isLastStep = stepIndex == totalSteps - 1;

    return Container(
      color: Colors.black.withValues(alpha: 0.5), // Semi-transparent scrim
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Swipe/Drag handle helper visual
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${stepIndex + 1} of $totalSteps',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF47B20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<RecipeDetailBloc>().add(CancelCooking());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF5F3EE),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8C8A87),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF5F3EE),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF47B20)),
                ),
              ),
              const SizedBox(height: 40),

              // Step Detail Card
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Giant illustration icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFF2D9),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFFF47B20),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Instruction Text
                        Text(
                          state.steps[stepIndex],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F1E1C),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Button controls
              Row(
                children: [
                  // Previous Step button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEFEBE4), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: stepIndex > 0
                            ? () {
                                context.read<RecipeDetailBloc>().add(PrevStep());
                              }
                            : null,
                        child: Text(
                          'Previous',
                          style: GoogleFonts.poppins(
                            color: stepIndex > 0 ? const Color(0xFF1F1E1C) : const Color(0xFFB5B3B0),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Next Step button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF47B20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (isLastStep) {
                            // Show beautiful success dialog and cancel cooking state
                            context.read<RecipeDetailBloc>().add(CancelCooking());
                            _showSuccessDialog(context, state.title);
                          } else {
                            context.read<RecipeDetailBloc>().add(NextStep());
                          }
                        },
                        child: Text(
                          isLastStep ? 'Finish!' : 'Next Step',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String recipeTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Celebration Lottie/Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF5E3),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFF4CAF50),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Congratulations! 🎉',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1E1C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You successfully prepared $recipeTitle. Enjoy your delicious home-cooked meal!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF8C8A87),
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47B20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Enjoy Meal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
