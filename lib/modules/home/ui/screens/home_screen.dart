import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/widgets/loader/shimmer_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/widgets/avatar/profile_avatar.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../../../shared/data/models/user_profile_model.dart';
import '../../../../shared/data/models/recipe_model.dart';
import '../../../../shared/services/notification_service.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentFeaturedPageIndex = 0;
  late final PageController _featuredPageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _featuredPageController =
        PageController(viewportFraction: 0.94, initialPage: 0);
  }

  /// Starts the 3.5-second auto-slide timer.
  /// Call this once the featured list is available (non-empty).
  void _startAutoSlide(int itemCount) {
    _autoSlideTimer?.cancel();
    if (itemCount <= 1) return;
    _autoSlideTimer =
        Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      final next = (_currentFeaturedPageIndex + 1) % itemCount;
      _featuredPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _featuredPageController.dispose();
    super.dispose();
  }

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
                      imageUrl: c.imageUrl,
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

            return Scaffold(
              backgroundColor: const Color(0xFFFAF7F2), // Premium Canvas background
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeBloc>().add(LoadHomeData());
                    // Wait for the bloc to emit a new loaded state
                    await Future.delayed(const Duration(milliseconds: 800));
                    if (context.mounted) {
                      OverlayNotification.show(
                        context,
                        message: 'Home feed updated successfully!',
                        type: NotificationType.success,
                      );
                    }
                  },
                  color: const Color(0xFFF47B20),
                  backgroundColor: Colors.white,
                  strokeWidth: 2.5,
                  displacement: 40,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
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

                      // ── Featured Hero Card (Carousel) ──────────────────────────
                      _buildFeaturedCarousel(
                        context,
                        state.featuredRecipes,
                        state.favoriteRecipeIds,
                      ),

                      const SizedBox(height: 32),

                      // ── Trending Recipes Section ────────────────────────────────
                      _buildTrendingSection(context, trendingRecipes),

                      const SizedBox(height: 32),

                      // ── Categories Horizontal List ──────────────────────────────
                       _buildCategoriesSection(context, categories),
                    ],
                  ),
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
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = 'Good morning, ';
    } else if (hour < 17) {
      greeting = 'Good afternoon, ';
    } else {
      greeting = 'Good evening, ';
    }

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
                  text: greeting,
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

  Widget _buildCategoriesSection(BuildContext context, List<CategoryItem> categories) {
    final displayedCategories = categories.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            GestureDetector(
              onTap: () => _showAllCategoriesBottomSheet(context, categories),
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
        _buildCategoriesList(displayedCategories),
      ],
    );
  }

  void _showCategoryRecipesBottomSheet(BuildContext context, CategoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.label} Foods',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1E1C),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEFEBE4),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF8C8A87)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<RecipeModel>>(
                  future: getIt<RecipeRepository>().getRecipes(category: item.label),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: 4,
                        itemBuilder: (_, __) => const ShimmerCard(
                          height: 220,
                          width: double.infinity,
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 48,
                              color: Color(0xFFB5B3B0),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No recipes found in this category",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: const Color(0xFF8C8A87),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final recipeList = snapshot.data!;
                    return ListView.builder(
                      itemCount: recipeList.length,
                      itemBuilder: (context, index) {
                        final recipe = recipeList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEFEBE4), width: 1),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: recipe.imageUrl.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: recipe.imageUrl,
                                          memCacheWidth: 200,
                                          memCacheHeight: 200,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: const Color(0xFFEFEBE4),
                                          ),
                                          errorWidget: (context, url, error) => Image.asset(
                                            AppImages.recipeRamen,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          recipe.imageUrl.isNotEmpty
                                              ? recipe.imageUrl
                                              : AppImages.recipeRamen,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Image.asset(
                                            AppImages.recipeRamen,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                recipe.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F1E1C),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF8C8A87)),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.cookTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF8C8A87),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF8C8A87)),
                                  const SizedBox(width: 2),
                                  Text(
                                    recipe.calories,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF8C8A87),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFF8C8A87),
                              ),
                              onTap: () {
                                RecipeDetailRoute(recipeId: recipe.id).push(context);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllCategoriesBottomSheet(BuildContext context, List<CategoryItem> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'All Categories',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1E1C),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final item = categories[index];
                    return _buildCategoryCard(context, item);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Bottom sheet: all trending recipes in a 2-column grid
  void _showAllTrendingBottomSheet(
      BuildContext context, List<RecipeItem> allItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return BlocBuilder<HomeBloc, HomeState>(
              builder: (context, homeState) {
                List<RecipeItem> currentItems = allItems;
                if (homeState is HomeLoaded) {
                  currentItems = homeState.trendingRecipes
                      .map((r) => RecipeItem(
                            id: r.id,
                            title: r.title,
                            imageUrl: r.imageUrl,
                            rating: r.rating.toString(),
                            reviews: r.reviews.toString(),
                            cookTime: r.cookTime,
                            calories: r.calories,
                            isFavorited: homeState.favoriteRecipeIds.contains(r.id),
                          ))
                      .toList();
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                      left: 24, right: 24, top: 20, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEBE4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          Text(
                            '${currentItems.length} recipes',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF8C8A87),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: currentItems.length,
                          itemBuilder: (ctx, index) {
                            final item = currentItems[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(dialogContext);
                                RecipeDetailRoute(recipeId: item.id).push(context);
                              },
                              child: _buildTrendingCard(context, item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Bottom sheet: all featured recipes in a 2-column grid (same style as trending)
  void _showAllFeaturedBottomSheet(
    BuildContext context,
    List<RecipeModel> allFeatured,
    List<String> favoriteRecipeIds,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return BlocBuilder<HomeBloc, HomeState>(
              builder: (context, homeState) {
                List<RecipeModel> currentFeatured = allFeatured;
                List<String> currentFavoriteIds = favoriteRecipeIds;
                if (homeState is HomeLoaded) {
                  currentFeatured = homeState.featuredRecipes;
                  currentFavoriteIds = homeState.favoriteRecipeIds;
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                      left: 24, right: 24, top: 20, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEBE4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Recipes',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1E1C),
                            ),
                          ),
                          Text(
                            '${currentFeatured.length} recipes',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF8C8A87),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 2-column grid — same UI as Trending View All
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: currentFeatured.length,
                          itemBuilder: (ctx, index) {
                            final r = currentFeatured[index];
                            final isFav = currentFavoriteIds.contains(r.id);
                            // Map RecipeModel -> RecipeItem for the trending card
                            final item = RecipeItem(
                              id: r.id,
                              title: r.title,
                              imageUrl: r.imageUrl,
                              rating: r.rating.toStringAsFixed(1),
                              reviews: r.reviews.toString(),
                              cookTime: r.cookTime,
                              calories: r.calories,
                              isFavorited: isFav,
                            );
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(dialogContext);
                                RecipeDetailRoute(recipeId: r.id).push(context);
                              },
                              child: _buildTrendingCard(context, item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _resolveCategoryImageUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('assets/')) return url;
    try {
      final parts = url.split('/');
      if (parts.length >= 2) {
        final bucket = parts[0];
        final path = parts.sublist(1).join('/');
        return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
      }
    } catch (_) {}
    return url;
  }

  Widget _buildCategoryCard(BuildContext context, CategoryItem item) {
    final resolvedUrl = _resolveCategoryImageUrl(item.imageUrl);
    final isAsset = resolvedUrl.startsWith('assets/');

    return GestureDetector(
      onTap: () {
        _showCategoryRecipesBottomSheet(context, item);
      },
      child: Container(
        width: 110,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A2818).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: isAsset
                    ? Image.asset(resolvedUrl, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: resolvedUrl,
                        memCacheWidth: 300,
                        memCacheHeight: 300,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ShimmerImagePlaceholder(),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFFFF2D9),
                          child: const Icon(Icons.restaurant_rounded, color: Color(0xFFF47B20)),
                        ),
                      ),
              ),
            ),
            // Dark Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            // Text at bottom center
            Positioned(
              bottom: 12,
              left: 8,
              right: 8,
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(List<CategoryItem> categories) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = categories[index];
          return _buildCategoryCard(context, item);
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel(
    BuildContext context,
    List<RecipeModel> featuredRecipes,
    List<String> favoriteRecipeIds,
  ) {
    if (featuredRecipes.isEmpty) {
      return const SizedBox.shrink();
    }

    const kMaxVisible = 4;
    final displayedRecipes = featuredRecipes.take(kMaxVisible).toList();

    // Start auto-slide once data is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoSlideTimer == null || !_autoSlideTimer!.isActive) {
        _startAutoSlide(displayedRecipes.length);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with View All ────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            if (featuredRecipes.length > kMaxVisible)
              GestureDetector(
                onTap: () => _showAllFeaturedBottomSheet(
                    context, featuredRecipes, favoriteRecipeIds),
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
        // ── Carousel PageView (max 4 items, auto-slides) ───────────────
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _featuredPageController,
            itemCount: displayedRecipes.length,
            onPageChanged: (index) {
              setState(() => _currentFeaturedPageIndex = index);
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final recipe = displayedRecipes[index];
              final isFavorited = favoriteRecipeIds.contains(recipe.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: GestureDetector(
                  onTap: () =>
                      RecipeDetailRoute(recipeId: recipe.id).push(context),
                  child: _buildFeaturedCard(
                    context,
                    recipe,
                    isFavorited: isFavorited,
                  ),
                ),
              );
            },
          ),
        ),
        if (displayedRecipes.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              displayedRecipes.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentFeaturedPageIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentFeaturedPageIndex == index
                      ? const Color(0xFFF47B20)
                      : const Color(0xFFEFEBE4),
                ),
              ),
            ),
          ),
        ],
      ],
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
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      memCacheWidth: 800,
                      memCacheHeight: 800,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ShimmerImagePlaceholder(),
                      errorWidget: (context, url, error) => Image.asset(
                        AppImages.heroBanner,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      imageUrl.isNotEmpty ? imageUrl : AppImages.heroBanner,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppImages.heroBanner,
                        fit: BoxFit.cover,
                      ),
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
                  final nextState = !isFavorited;
                  context.read<HomeBloc>().add(ToggleFavoriteRecipe(recipe.id));
                  OverlayNotification.show(
                    context,
                    message: nextState
                        ? 'Added "${recipe.title}" to favorites! ❤️'
                        : 'Removed "${recipe.title}" from favorites 💔',
                    type: nextState
                        ? NotificationType.success
                        : NotificationType.warning,
                  );
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              cookTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              calories,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => RecipeDetailRoute(recipeId: recipe?.id ?? 'r0000000-0000-0000-0000-000000000001')
                          .push(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
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
    const kMaxVisible = 5;
    final displayedItems = trendingRecipes.take(kMaxVisible).toList();

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
              onTap: () => _showAllTrendingBottomSheet(context, trendingRecipes),
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
            itemCount: displayedItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = displayedItems[index];
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
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const ShimmerImagePlaceholder(),
                            errorWidget: (context, url, error) => Image.asset(
                              AppImages.recipeRamen,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            item.imageUrl.isNotEmpty ? item.imageUrl : AppImages.recipeRamen,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              AppImages.recipeRamen,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                // Bookmark circular button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      final nextState = !item.isFavorited;
                      context.read<HomeBloc>().add(ToggleFavoriteRecipe(item.id));
                      OverlayNotification.show(
                        context,
                        message: nextState
                            ? 'Added "${item.title}" to favorites! ❤️'
                            : 'Removed "${item.title}" from favorites 💔',
                        type: nextState
                            ? NotificationType.success
                            : NotificationType.warning,
                      );
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
    return SingleChildScrollView(
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
                    CustomShimmer(width: 140, height: 28, borderRadius: BorderRadius.circular(8)),
                    const SizedBox(height: 8),
                    CustomShimmer(width: 200, height: 16, borderRadius: BorderRadius.circular(6)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const CustomShimmer(width: 48, height: 48, shape: BoxShape.circle),
            ],
          ),
          const SizedBox(height: 28),

          // Search Bar Shimmer
          CustomShimmer(
            height: 52,
            width: double.infinity,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 28),

          // Featured Hero Card Shimmer
          CustomShimmer(
            height: 280,
            width: double.infinity,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(height: 32),

          // Trending Section Header Shimmer
          CustomShimmer(width: 180, height: 24, borderRadius: BorderRadius.circular(6)),
          const SizedBox(height: 16),

          // Trending Recipes list Shimmer
          Row(
            children: List.generate(2, (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 1 ? 0 : 16),
                child: CustomShimmer(
                  height: 250,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )),
          ),
          const SizedBox(height: 32),

          // Categories Shimmer
          Row(
            children: List.generate(4, (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                child: CustomShimmer(
                  height: 130,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class CategoryItem {
  final String label;
  final String imageUrl;
  CategoryItem({
    required this.label,
    required this.imageUrl,
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
