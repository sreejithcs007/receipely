import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/widgets/loader/shimmer_card.dart';
import '../../../../shared/di/service_locator.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import '../../bloc/favorites_bloc.dart';
import '../../bloc/favorites_event.dart';
import '../../bloc/favorites_state.dart';

import '../../../../shared/services/notification_service.dart';
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoritesBloc(
        getIt<UserRepository>(),
      )..add(LoadFavoritesPage()),
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
                    _buildHeader(context, state),

                    const SizedBox(height: 20),

                    // ── Scrollable Content Area ─────────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<FavoritesBloc>().add(LoadFavoritesPage());
                          await Future.delayed(const Duration(milliseconds: 800));
                          if (context.mounted) {
                            OverlayNotification.show(
                              context,
                              message: 'Favorites list refreshed!',
                              type: NotificationType.success,
                            );
                          }
                        },
                        color: const Color(0xFFF47B20),
                        backgroundColor: Colors.white,
                        strokeWidth: 2.5,
                        displacement: 40,
                        child: state.isLoading
                            ? _buildShimmerGrid()
                            : SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (state.favorites.isEmpty)
                                      _buildEmptyState('No favorites yet', 'Bookmark recipes to see them here.')
                                    else
                                      _buildRecipesGrid(context, state),
                                    const SizedBox(height: 24),
                                  ],
                                ),
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

  Widget _buildHeader(BuildContext context, FavoritesState state) {
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
        // Tune list circle button (Filter/Sort)
        GestureDetector(
          onTap: () => _showSortMenu(context, state),
          child: Container(
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
        ),
      ],
    );
  }

  void _showSortMenu(BuildContext context, FavoritesState state) {
    final favoritesBloc = context.read<FavoritesBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                child: Text(
                  'Sort Favorites',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1E1C),
                  ),
                ),
              ),
              const Divider(color: Color(0xFFEFEBE4)),
              _buildSortOption(
                context,
                favoritesBloc,
                label: 'Latest to Oldest',
                type: FavoritesSortType.latestToOldest,
                current: state.sortType,
              ),
              _buildSortOption(
                context,
                favoritesBloc,
                label: 'Oldest to Latest',
                type: FavoritesSortType.oldestToLatest,
                current: state.sortType,
              ),
              _buildSortOption(
                context,
                favoritesBloc,
                label: 'Alphabetical Order (A-Z)',
                type: FavoritesSortType.alphabeticalAZ,
                current: state.sortType,
              ),
              _buildSortOption(
                context,
                favoritesBloc,
                label: 'Alphabetical Order (Z-A)',
                type: FavoritesSortType.alphabeticalZA,
                current: state.sortType,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    FavoritesBloc favoritesBloc, {
    required String label,
    required FavoritesSortType type,
    required FavoritesSortType current,
  }) {
    final isSelected = type == current;
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? const Color(0xFFF47B20) : const Color(0xFF1F1E1C),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Color(0xFFF47B20))
          : null,
      onTap: () {
        favoritesBloc.add(SortFavorites(type));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80.0),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF2D9),
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                color: Color(0xFFF47B20),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const ShimmerCard(height: 220, width: double.infinity);
      },
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
                      // Bookmark/favorite overlay button (white circle with red filled heart)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            context.read<FavoritesBloc>().add(
                                ToggleFavoriteItemState(item.id));
                            OverlayNotification.show(
                              context,
                              message:
                                  'Removed "${item.title}" from saved recipes 💔',
                              type: NotificationType.warning,
                            );
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
}
