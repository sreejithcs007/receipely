import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/widgets/avatar/profile_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeCategoryIndex = 0;

  final List<CategoryItem> _categories = [
    CategoryItem(
      label: 'Breakfast',
      icon: Icons.wb_sunny_rounded,
      activeBgColor: const Color(0xFFFFF2D9),
      iconColor: const Color(0xFFF47B20),
    ),
    CategoryItem(
      label: 'Lunch',
      icon: Icons.eco_rounded,
      activeBgColor: const Color(0xFFEAF5E3),
      iconColor: const Color(0xFF4CAF50),
    ),
    CategoryItem(
      label: 'Dinner',
      icon: Icons.dinner_dining_rounded,
      activeBgColor: const Color(0xFFFDECEB),
      iconColor: const Color(0xFFE91E63),
    ),
    CategoryItem(
      label: 'Dessert',
      icon: Icons.cake_rounded,
      activeBgColor: const Color(0xFFFAF0F5),
      iconColor: const Color(0xFF9C27B0),
    ),
  ];

  final List<RecipeItem> _trendingRecipes = [
    RecipeItem(
      id: 'r2',
      title: 'Avocado Toast with Poached Egg',
      imageUrl: AppImages.recipeAvocadoToast,
      rating: '4.8',
      reviews: '128',
      cookTime: '15 min',
      calories: '320 cal',
    ),
    RecipeItem(
      id: 'r3',
      title: 'Honey Glazed Salmon',
      imageUrl: AppImages.recipeSalmon,
      rating: '4.7',
      reviews: '99',
      cookTime: '25 min',
      calories: '450 cal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),

              const SizedBox(height: 24),

              // ── Search Bar Trigger ──────────────────────────────────────
              _buildSearchBar(),

              const SizedBox(height: 28),

              // ── Categories Horizontal List ──────────────────────────────
              _buildCategoriesList(),

              const SizedBox(height: 28),

              // ── Featured Hero Card ──────────────────────────────────────
              _buildFeaturedCard(),

              const SizedBox(height: 32),

              // ── Trending Recipes Section ────────────────────────────────
              _buildTrendingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Good morning, ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1E1C),
                ),
                children: [
                  TextSpan(
                    text: 'Sarah',
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
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8C8A87),
              ),
            ),
          ],
        ),
        const Spacer(),
        ProfileAvatar(
          name: 'Sarah',
          imageUrl: AppImages.chefAvatar,
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
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/icons/actions/filter.png',
                    height: 20,
                    width: 20,
                    color: const Color(0xFF8C8A87),
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF8C8A87),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _categories[index];
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

  Widget _buildFeaturedCard() {
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
              child: Image.asset(
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
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                color: Color(0xFF1F1E1C),
                size: 20,
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
                  'Creamy Garlic\nChicken Pasta',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rich, creamy, and full of flavor. Ready in under 30 minutes!',
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
                          '30 min',
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
                          '560 cal',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => const RecipeDetailRoute(recipeId: 'featured_1')
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

  Widget _buildTrendingSection() {
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
              onTap: () => const CategoriesRoute().push(context),
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
            itemCount: _trendingRecipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = _trendingRecipes[index];
              return _buildTrendingCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(RecipeItem item) {
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
                    child: Image.asset(
                      item.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Bookmark circular button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.bookmark_outline_rounded,
                      color: Color(0xFF8C8A87),
                      size: 18,
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

  RecipeItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.cookTime,
    required this.calories,
  });
}
