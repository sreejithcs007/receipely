import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../router/routes.dart';
import '../../bloc/favorites_bloc.dart';
import '../../bloc/favorites_event.dart';
import '../../bloc/favorites_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoritesBloc()..add(LoadFavoritesPage()),
      child: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2), // Premium Canvas background
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Row ──────────────────────────────────────────
                    _buildHeader(context),

                    const SizedBox(height: 20),

                    // ── Tab Bar Capsule Selector ────────────────────────────
                    _buildTabSelector(context, state),

                    const SizedBox(height: 24),

                    // ── Scrollable Content Area ─────────────────────────────
                    Expanded(
                      child: state.isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF47B20)))
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (state.selectedTabIndex == 0) ...[
                                    // Recipe Grid
                                    if (state.favorites.isEmpty)
                                      _buildEmptyState('No favorites yet', 'Bookmark recipes to see them here.')
                                    else
                                      _buildRecipesGrid(context, state),

                                    const SizedBox(height: 24),

                                    // Collections Row below recipes
                                    if (state.collections.isNotEmpty)
                                      _buildCollectionsGrid(context, state),
                                  ] else ...[
                                    // Collections Tab Only
                                    if (state.collections.isEmpty)
                                      _buildEmptyState('No collections yet', 'Create folders to organize your recipes.')
                                    else
                                      _buildCollectionsGrid(context, state),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Favorites',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1E1C),
          ),
        ),
        // Tune list circle button
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF5F3EE),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Color(0xFF1F1E1C),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(BuildContext context, FavoritesState state) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // All Tab
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.read<FavoritesBloc>().add(const ChangeFavoritesTab(0));
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
                    'All',
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
          // Collections Tab
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.read<FavoritesBloc>().add(const ChangeFavoritesTab(1));
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
                    'Collections',
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80.0),
        child: Column(
          children: [
            const Icon(Icons.bookmark_outline_rounded, size: 64, color: Color(0xFFB5B3B0)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1E1C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF8C8A87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesGrid(BuildContext context, FavoritesState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: state.favorites.length,
      itemBuilder: (context, index) {
        final item = state.favorites[index];
        return GestureDetector(
          onTap: () {
            RecipeDetailRoute(recipeId: item.id).push(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A2818).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cover Image Stack
                SizedBox(
                  height: 120,
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
                      // Bookmark/favorite overlay button (white circle with red filled heart)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            context.read<FavoritesBloc>().add(ToggleFavoriteItemState(item.id));
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFEA4335), // Red filled heart
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1E1C),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Cook time + difficulty
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
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF8C8A87),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.difficulty,
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
          ),
        );
      },
    );
  }

  Widget _buildCollectionsGrid(BuildContext context, FavoritesState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 78,
      ),
      itemCount: state.collections.length,
      itemBuilder: (context, index) {
        final col = state.collections[index];

        // Map colors for custom look
        Color folderColor;
        if (col.badgeHexColor == 0xFFFFF2D9) {
          folderColor = const Color(0xFFF47B20); // Orange folder
        } else if (col.badgeHexColor == 0xFFEAF5E3) {
          folderColor = const Color(0xFF4CAF50); // Green folder
        } else {
          folderColor = const Color(0xFF9C27B0); // Purple folder fallback
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3A2818).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Folder icon circular background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(col.badgeHexColor),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: folderColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      col.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1E1C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${col.recipeCount} recipes',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF8C8A87),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB5B3B0),
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}
