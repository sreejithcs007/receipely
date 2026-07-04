import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/widgets/avatar/profile_avatar.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../../../shared/data/models/user_profile_model.dart';
import '../../../../shared/data/models/recipe_model.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';

IconData _getCategoryIcon(String name) {
  switch (name.toLowerCase()) {
    case 'breakfast':
      return Icons.wb_sunny_rounded;
    case 'lunch':
      return Icons.eco_rounded;
    case 'dinner':
      return Icons.dinner_dining_rounded;
    case 'desserts':
    case 'dessert':
      return Icons.cake_rounded;
    case 'snacks':
    case 'snack':
      return Icons.cookie_rounded;
    case 'appetizers':
      return Icons.restaurant_menu_rounded;
    case 'soups':
      return Icons.soup_kitchen_rounded;
    case 'salads':
      return Icons.restaurant_rounded;
    case 'beverages':
      return Icons.local_cafe_rounded;
    case 'bakery':
      return Icons.bakery_dining_rounded;
    case 'seafood':
      return Icons.set_meal_rounded;
    default:
      return Icons.restaurant_menu_rounded;
  }
}

Color _getCategoryActiveBgColor(String name) {
  switch (name.toLowerCase()) {
    case 'breakfast':
      return const Color(0xFFFFF2D9);
    case 'lunch':
      return const Color(0xFFEAF5E3);
    case 'dinner':
      return const Color(0xFFFDECEB);
    case 'desserts':
    case 'dessert':
      return const Color(0xFFFAF0F5);
    case 'snacks':
      return const Color(0xFFFFF2D9);
    default:
      return const Color(0xFFFFF2D9);
  }
}

Color _getCategoryIconColor(String name) {
  switch (name.toLowerCase()) {
    case 'breakfast':
      return const Color(0xFFF47B20);
    case 'lunch':
      return const Color(0xFF4CAF50);
    case 'dinner':
      return const Color(0xFFE91E63);
    case 'desserts':
    case 'dessert':
      return const Color(0xFF9C27B0);
    case 'snacks':
      return const Color(0xFFF47B20);
    default:
      return const Color(0xFFF47B20);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        getIt<RecipeRepository>(),
        getIt<UserRepository>(),
      )..add(LoadHomeData()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return Scaffold(
              backgroundColor: const Color(0xFFFAF7F2),
              body: SafeArea(
                child: _buildHomeShimmer(context),
              ),
            );
          }
          if (state is HomeError) {
            return Scaffold(
              backgroundColor: const Color(0xFFFAF7F2),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFDECEB),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEA4335),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Failed to load recipes',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F1E1C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: const Color(0xFF8C8A87),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () {
                          context.read<HomeBloc>().add(LoadHomeData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF47B20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (state is HomeLoaded) {
            final categories = state.categories
                .map((c) => CategoryItem(
                      label: c.name,
                      icon: _getCategoryIcon(c.name),
                      activeBgColor: _getCategoryActiveBgColor(c.name),
                      iconColor: _getCategoryIconColor(c.name),
                    ))
                .toList();

            final trendingRecipes = state.trendingRecipes
                .map((r) => RecipeItem(
                      id: r.id,
                      title: r.title,
                      imageUrl: r.imageUrl,
                      rating: r.rating.toString(),
                      reviews: r.reviews.toString(),
                      cookTime: r.cookTime,
                      calories: r.calories,
                      isFavorited: state.favoriteRecipeIds.contains(r.id),
                    ))
                .toList();

            final featuredRecipe = state.featuredRecipes.firstOrNull;

            return Scaffold(
              backgroundColor: const Color(0xFFFAF7F2), // Premium Canvas background
              body: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header Row ──────────────────────────────────────────────
                      _buildHeader(state.userProfile),

                      const SizedBox(height: 24),

                      // ── Search Bar Trigger ──────────────────────────────────────
                      _buildSearchBar(),

                      const SizedBox(height: 28),

                      // ── Categories Horizontal List ──────────────────────────────
                      _buildCategoriesList(categories),

                      const SizedBox(height: 28),

                      // ── Featured Hero Card ──────────────────────────────────────
                      _buildFeaturedCard(
                        context,
                        featuredRecipe,
                        isFavorited: featuredRecipe != null &&
                            state.favoriteRecipeIds.contains(featuredRecipe.id),
                      ),

                      const SizedBox(height: 32),

                      // ── Trending Recipes Section ────────────────────────────────
                      _buildTrendingSection(context, trendingRecipes),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(UserProfileModel? profile) {
    final nameToSplit = (profile?.name != null && profile!.name.trim().isNotEmpty)
        ? profile.name
        : (profile?.email != null && profile!.email.isNotEmpty)
            ? profile.email.split('@').first
            : 'Sarah';
    final displayName = nameToSplit.split(' ').first;
    final avatarUrl = profile?.avatarUrl ?? '';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: 'Good morning, ',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1E1C),
                  ),
                  children: [
                    TextSpan(
                      text: displayName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF47B20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "What's cooking today?",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8C8A87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ProfileAvatar(
          name: displayName,
          imageUrl: avatarUrl.isNotEmpty ? avatarUrl : AppImages.chefAvatar,
          radius: 24.0,
          onTap: () => const ProfileRoute().go(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => const SearchRoute().go(context),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEBE4), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFF8C8A87), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search recipes, ingredients...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFFB5B3B0),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFEFEBE4), width: 1),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF8C8A87),
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(List<CategoryItem> categories) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isActive = _activeCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategoryIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? item.activeBgColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? item.iconColor.withValues(alpha: 0.25)
                      : const Color(0xFFEFEBE4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: isActive ? item.iconColor : const Color(0xFF8C8A87),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1E1C),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, RecipeModel? recipe, {required bool isFavorited}) {
    final title = recipe?.title ?? 'Creamy Garlic\nChicken Pasta';
    final description = recipe?.description ?? 'Rich, creamy, and full of flavor. Ready in under 30 minutes!';
    final cookTime = recipe?.cookTime ?? '30 min';
    final calories = recipe?.calories ?? '560 cal';
    final imageUrl = recipe?.imageUrl ?? '';

    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2818).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppImages.heroBanner,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      AppImages.heroBanner,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          // Badge "Featured" (Top Left)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFFFFF2D9),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Featured',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bookmark Button (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: InkWell(
              onTap: () {
                if (recipe != null) {
                  context.read<HomeBloc>().add(ToggleFavoriteRecipe(recipe.id));
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : const Color(0xFF1F1E1C),
                  size: 20,
                ),
              ),
            ),
          ),
          // Details Content
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cookTime,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          calories,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => RecipeDetailRoute(recipeId: recipe?.id ?? 'r0000000-0000-0000-0000-000000000001')
                          .push(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47B20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Recipe',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
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
  Widget _buildTrendingSection(BuildContext context, List<RecipeItem> trendingRecipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trending Recipes',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            GestureDetector(
              onTap: () => const SearchRoute(q: 'trending').go(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF47B20),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFF47B20),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: trendingRecipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = trendingRecipes[index];
              return GestureDetector(
                onTap: () => RecipeDetailRoute(recipeId: item.id).push(context),
                child: _buildTrendingCard(context, item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(BuildContext context, RecipeItem item) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2818).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with Bookmark
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: item.imageUrl.startsWith('http')
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              AppImages.recipeRamen,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            item.imageUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                // Bookmark circular button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      context.read<HomeBloc>().add(ToggleFavoriteRecipe(item.id));
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        item.isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: item.isFavorited ? Colors.red : const Color(0xFF8C8A87),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Metadata details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1E1C),
                  ),
                ),
                const SizedBox(height: 6),
                // Star ratings
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 16,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 16,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 16,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 16,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.rating} (${item.reviews})',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8A87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Info footer
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF8C8A87),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.cookTime,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8A87),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFF8C8A87),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.calories,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8C8A87),
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

  Widget _buildHomeShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEFEBE4),
      highlightColor: const Color(0xFFF5F3EE),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row Shimmer
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 140, height: 28, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 200, height: 16, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 28),

            // Search Bar Shimmer
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 28),

            // Categories Shimmer
            Row(
              children: List.generate(4, (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 28),

            // Featured Hero Card Shimmer
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 32),

            // Trending Section Header Shimmer
            Container(width: 180, height: 24, color: Colors.white),
            const SizedBox(height: 16),

            // Trending Recipes list Shimmer
            Row(
              children: List.generate(2, (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 1 ? 0 : 16),
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  final String label;
  final IconData icon;
  final Color activeBgColor;
  final Color iconColor;
  CategoryItem({
    required this.label,
    required this.icon,
    required this.activeBgColor,
    required this.iconColor,
  });
}

class RecipeItem {
  final String id;
  final String title;
  final String imageUrl;
  final String rating;
  final String reviews;
  final String cookTime;
  final String calories;
  final bool isFavorited;

  RecipeItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.cookTime,
    required this.calories,
    required this.isFavorited,
  });
}
